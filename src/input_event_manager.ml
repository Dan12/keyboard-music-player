open Tsdl.Sdl.Event

type input_event_state = {
  keyboard: Keyboard.keyboard;
  layout: Keyboard_layout.keyboard_layout;
}

let input_event_singleton = ref None

let init keyboard layout =
  input_event_singleton := Some {
    keyboard = keyboard;
    layout = layout;
  }

let handle_keyboard input_event =
  match !input_event_singleton with
  | None -> ()
  | Some ie ->
    match State_manager.get_state () with
    | State_manager.SKeyboard ->
      (* get the mapped output *)
      let output = Keyboard_layout.process_key input_event ie.layout in
      (* pass it to the keyboard and check if it modifies state *)
      if Keyboard.process_event output ie.keyboard then
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
        ()
    | _ -> ()

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