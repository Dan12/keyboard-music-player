open Tsdl.Sdl.Event
open Model

let input_event_singleton = ref None
let recent_click = ref (Unix.gettimeofday())

let handle_keyboard_output output =
  let keyboard = Model.get_keyboard () in
  (* pass it to the keyboard and check if it modifies state *)
  if Keyboard.process_event output keyboard then
    (* if it does, pass it to the sound manager *)
    begin
      match output with
      | Keyboard_layout.KOKeydown (r,c) ->
        Sound_manager.key_pressed (r,c)
      | Keyboard_layout.KOKeyup (r,c) ->
        Sound_manager.key_released (r,c)
      | _ -> ()
    end
  else
    match output with
    | Keyboard_layout.KOSoundpackSet i ->
      let song = Model.get_song () in
      Song.set_sound_pack i song
    | Keyboard_layout.KOSpace ->
      if Model.get_state() = SKeyboard then
        if Model.midi_is_playing() then
          Model.pause_midi()
        else
          Model.start_midi()
    | _ -> ()

(* [handle_keyboard input_event] handles the effects of pressing and releasing
 * a key on the keyboard which is encoded in [input_event]. *)
let handle_keyboard input_event =
  match Model.get_state () with
  | SKeyboard | SSynthesizer->
    let layout = Model.get_keyboard_layout () in
    (* get the mapped output *)
    let output = Keyboard_layout.process_key input_event layout in
    handle_keyboard_output output
  | _ -> ()

let clear_keyboard () =
  let layout = get_keyboard_layout() in
  let keyboard = get_keyboard() in
  let rows = Keyboard_layout.get_rows layout in
  let cols = Keyboard_layout.get_cols layout in
  for row = 0 to rows - 1 do
    for col = 0 to cols - 1 do
      Keyboard.process_event (Keyboard_layout.KOKeyup (row, col)) keyboard |> ignore
    done;
  done

(* [handle_mouse_up x y t] registers whatever changes may occur with when a
 * mouse click is lifted. The change will depend on (x,y) which are the
 * coordinates of the lifting mouse click.
 *
 * Changes include setting is_scrubbing fields to false and executing
 * the effects of various buttons. *)
let handle_mouse_up x y =
  (* Stops scrubbing and sliding by setting is_scrubbing fields to false. *)
  if Model.is_scrubbing() then
    begin
      Model.set_scrubbing false;
      clear_keyboard();
    end;
  if Model.is_bpm_scrubbing() then
    begin
      Model.set_bpm_scrubbing false;
      clear_keyboard();
    end;

  Model.set_a_sliding false;
  Model.set_d_sliding false;
  Model.set_s_sliding false;
  Model.set_r_sliding false;

  (* Executes the effects of whatever button is pressed if any button was in
   * fact pressed. *)
  let iter = fun _ b -> Button.up_press b (x, y) in
  match Model.get_state () with
  | SKeyboard ->
    List.iteri iter (Model.get_midi_buttons());
    iter () (Model.get_synth_button())
  | SFileChooser ->
    List.iteri iter (Model.get_file_buttons());
    List.iteri iter (Model.get_filename_buttons())
  | SSynthesizer ->
    iter () (Model.get_play_button());
    iter () (Model.get_synth_grid());
    List.iteri iter (Model.get_filter_buttons());
    List.iteri iter (Model.get_wave_buttons())

(* [handle_mouse_down x y] registers whatever changes may occur when a mouse
 * is clicked. The change will depend of (x,y) which represent the coordinates
 * of where the mouse was clicked.
 *
 * Changes include setting is_scrubbing fields to true as well as executing the
 * effects of various buttons. *)
let handle_mouse_down x y =
  let iter = fun _ b -> Button.down_press b (x, y) in
  match Model.get_state() with
  | SKeyboard ->
    Model.set_scrubbing (Gui.scrub_pressed (x, y) Model.Scrub);
    Model.set_bpm_scrubbing (Gui.scrub_pressed (x, y) Model.BPM);
  | SFileChooser -> ()
  | SSynthesizer ->
    Model.set_a_sliding (Gui.scrub_pressed (x,y) Model.A_slider);
    Model.set_d_sliding (Gui.scrub_pressed (x,y) Model.D_slider);
    Model.set_s_sliding (Gui.scrub_pressed (x,y) Model.S_slider);
    Model.set_r_sliding (Gui.scrub_pressed (x,y) Model.R_slider);
    iter () (Model.get_synth_grid())

(* [handle_scrubbing x] handles the effects of moving one of the 6 sliders in
 * our GUI. Since they are all horizontal sliders, [x] represents the x
 * coordinate of where the slider is.
 *
 * Effects of manipulating the slider include updating the GUI with the new
 * position for the slider and setting whatever variable the slider represents
 * to its new value based on the new location of the slider. *)
let handle_scrubbing x =
  let set_scrub mini maxi =
    let curr = float_of_int x in
    if curr > maxi then maxi
    else if curr < mini then mini
    else curr in

  (* Handles scrubbing for the midi player. *)
  if Model.is_scrubbing() then
    begin
      let scrub_x = set_scrub (Model.get_scrub_pos_min())
          (Model.get_scrub_pos_max()) in
      Model.set_scrub_pos scrub_x
    end;

  (* Handles sliding for the bpm_slider. *)
  if Model.is_bpm_scrubbing() then
    begin
      let scrub_x = set_scrub (Model.get_bpm_pos_min())
          (Model.get_bpm_pos_max()) in
      Model.set_bpm_pos scrub_x
    end;

  (* Handles sliding for the four adsr slider in synthesizer. *)
  let adsr_length = Model.get_adsr_pos_max() -. Model.get_adsr_pos_min() in
  let (a,d,s,r) = Model.get_adsr_params() in
  let scrub_x = set_scrub (Model.get_adsr_pos_min())
      (Model.get_adsr_pos_max()) in
  let new_val = (scrub_x -. Model.get_adsr_pos_min()) /. adsr_length in
  if Model.get_a_sliding() then
      Model.set_adsr_params (new_val,d,s,r);
  if Model.get_d_sliding() then
    Model.set_adsr_params (a,new_val,s,r);
  if Model.get_s_sliding() then
    Model.set_adsr_params (a,d,new_val,r);
  if Model.get_r_sliding() then
    Model.set_adsr_params (a,d,s,new_val);
  ()

(* [handle_mouse_move x y] handles the effects of dragging the mouse to a new
 * position with coordinates (x,y). Effects include the dragging of various
 * sliders as well as the drawing in the synthesizer grid. *)
let handle_mouse_move x y =
  let iter = fun _ b -> Button.on_move b (x, y) in
  match Model.get_state() with
  | SKeyboard ->
    handle_scrubbing x
  | SFileChooser -> ()
  | SSynthesizer ->
    handle_scrubbing x;
    iter () (Model.get_synth_grid())


let event_callback event =
  match enum (get event typ) with
  | `Key_down ->
    let keycode = get event keyboard_keycode in
    handle_keyboard (Keyboard_layout.KIKeydown keycode)
  | `Key_up ->
    let keycode = get event keyboard_keycode in
    handle_keyboard (Keyboard_layout.KIKeyup keycode)
  | `Mouse_button_down ->
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_down mouse_x mouse_y
  | `Mouse_button_up ->
    let click = Unix.gettimeofday() in
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_up mouse_x mouse_y;
    recent_click := click
  | `Mouse_motion ->
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_move mouse_x mouse_y
  | `Mouse_wheel ->
    (* let scroll_dx = get event mouse_wheel_x in
    let scroll_dy = get event mouse_wheel_y in *)
    ()
  | _ -> ()
