open Tsdl.Sdl.Event
open Button
open Model

let input_event_singleton = ref None

let handle_keyboard input_event =
  match Model.get_state () with
  | Model.SKeyboard ->
    let layout = Model.get_keyboard_layout () in
    let keyboard = Model.get_keyboard () in
    (* get the mapped output *)
    let output = Keyboard_layout.process_key input_event layout in
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
      (match output with
      | Keyboard_layout.KOSoundpackSet i ->
        let song = Model.get_song () in
        Song.set_sound_pack i song
      | _ -> ())
  | _ -> ()

let handle_mouse_up x y =
  match Gui.button_pressed (x, y) with
  | Some button ->
    begin
      match button with
      | Load -> Model.set_state SFileChooser;
      | Play -> print_endline("Play pressed!")
      | Pause -> print_endline("Pause pressed!")
    end
  | None -> ()

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
    print_endline ((string_of_int mouse_x) ^ ", " ^ (string_of_int mouse_y))
  | `Mouse_button_up ->
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_up mouse_x mouse_y;
    print_endline ((string_of_int mouse_x) ^ ", " ^ (string_of_int mouse_y))
  | `Mouse_motion ->
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    print_endline ((string_of_int mouse_x) ^ ", " ^ (string_of_int mouse_y))
  | `Mouse_wheel ->
    let scroll_dx = get event mouse_wheel_x in
    let scroll_dy = get event mouse_wheel_y in
    print_endline ((string_of_int scroll_dx) ^ ", " ^ (string_of_int scroll_dy))
  | _ -> ()
