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
      if Model.midi_is_playing() then Model.pause_midi()
      else Model.start_midi()
    | _ -> ()

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

let handle_mouse_up x y t =
  (Model.set_scrubbing false;
  clear_keyboard());
  Model.set_bpm_scrubbing false;
  Model.set_a_sliding false;
  Model.set_d_sliding false;
  Model.set_s_sliding false;
  Model.set_r_sliding false;
  clear_keyboard();
  let iter = fun _ b -> Button_standard.up_press b (x, y) in
  match Model.get_state () with
  | SKeyboard ->
    List.iteri iter (Model.get_midi_buttons());
    iter () (Model.get_synth_button())
  | SFileChooser ->
    List.iteri iter (Model.get_file_buttons());
    List.iteri iter (Model.get_filename_buttons())
  | SSynthesizer ->
    iter () (Model.get_play_button());
    iter () (Model.get_synth_grid())


let handle_mouse_down x y =
  let iter = fun _ b -> Button_standard.down_press b (x, y) in
  match Model.get_state() with
  | SKeyboard ->
    Model.set_scrubbing (Gui.scrub_pressed (x, y) "scrub");
    Model.set_bpm_scrubbing (Gui.scrub_pressed (x, y) "bpm");
  | SFileChooser -> ()
  | SSynthesizer ->
    Model.set_a_sliding (Gui.scrub_pressed (x,y) "a_slider");
    Model.set_d_sliding (Gui.scrub_pressed (x,y) "d_slider");
    Model.set_s_sliding (Gui.scrub_pressed (x,y) "s_slider");
    Model.set_r_sliding (Gui.scrub_pressed (x,y) "r_slider");
    iter () (Model.get_synth_grid())

let handle_scrubbing x =
  let set_scrub mini maxi =
    let curr = float_of_int x in
    if curr > maxi then maxi
    else if curr < mini then mini
    else curr in
  if Model.is_scrubbing() then
    begin
      let scrub_x = set_scrub (Model.get_scrub_pos_min())
          (Model.get_scrub_pos_max()) in
      Model.set_scrub_pos scrub_x
    end;
  if Model.is_bpm_scrubbing() then
    begin
      let scrub_x = set_scrub (Model.get_bpm_pos_min())
          (Model.get_bpm_pos_max()) in
      Model.set_bpm_pos scrub_x
    end;
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

let handle_mouse_move x y =
  let iter = fun _ b -> Button_standard.on_move b (x, y) in
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
    (* print_endline (string_of_int keycode); *)
    handle_keyboard (Keyboard_layout.KIKeydown keycode)
  | `Key_up ->
    let keycode = get event keyboard_keycode in
    (* print_endline (string_of_int keycode); *)
    handle_keyboard (Keyboard_layout.KIKeyup keycode)
  | `Mouse_button_down ->
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_down mouse_x mouse_y
  | `Mouse_button_up ->
    let click = Unix.gettimeofday() in
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_up mouse_x mouse_y click;
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
