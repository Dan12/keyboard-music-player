open Tsdl.Sdl.Event

type input_event_state = {
  keyboard: Keyboard.keyboard;
  layout: Keyboard_layout.keyboard_layout;
}

let input_event_singleton = ref None

let init keyboard layout =
  input_event_singleton := {
    keyboard = keyboard;
    layout = layout;
  }

let event_callback event =
  match enum (get event typ) with
  | `Key_down ->
    let keycode = get event keyboard_keycode in
    print_endline (string_of_int keycode)
  | `Key_up -> 
    let keycode = get event keyboard_keycode in
    print_endline (string_of_int keycode)
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