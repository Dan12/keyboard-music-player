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
  if Model.is_scrubbing() then
    (Model.set_scrubbing false;
     clear_keyboard());
  if Model.is_bpm_scrubbing() then
     Model.set_bpm_scrubbing false;
  clear_keyboard();
  match Model.get_state () with
  | SKeyboard ->
    let iter = fun _ b -> Button_standard.up_press b (x, y) in
    List.iteri iter (Model.get_midi_buttons())
  | SFileChooser ->
    let iter = fun i b -> Button_standard.up_press b (x, y) in
    List.iteri iter (Model.get_file_buttons());
    List.iteri iter (Model.get_filename_buttons())
  | SSynthesizer -> ()

let handle_mouse_down x y =
  match Model.get_state() with
  | SKeyboard ->
    Model.set_scrubbing (Gui.scrub_pressed (x, y) "scrub");
    Model.set_bpm_scrubbing (Gui.scrub_pressed (x, y) "bpm")
  | SFileChooser -> ()
  | SSynthesizer -> ()

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
    let mouse_x = get event mouse_button_x |> float_of_int in
    if Model.is_scrubbing() then
    begin
      let scrub_x = (
        if mouse_x > Model.get_scrub_pos_max() then
          Model.get_scrub_pos_max()
        else if mouse_x < Model.get_scrub_pos_min() then
          Model.get_scrub_pos_min()
        else
          mouse_x) in
      Model.set_scrub_pos scrub_x
    end;
    if Model.is_bpm_scrubbing() then
    begin
      let scrub_x = (
        if mouse_x > Model.get_bpm_pos_max() then
          Model.get_bpm_pos_max()
        else if mouse_x < Model.get_bpm_pos_min() then
          Model.get_bpm_pos_min()
        else
          mouse_x) in
      Model.set_bpm_pos scrub_x
    end
  | `Mouse_wheel ->
    (* let scroll_dx = get event mouse_wheel_x in
    let scroll_dy = get event mouse_wheel_y in *)
    ()
  | _ -> ()
