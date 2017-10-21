#require "graphics";;
open Graphics;;

let handle_event = function
  | {keypressed=true; key=keycode} (*key pressed*)
    -> print_char keycode;
    print_endline ""
  | {button=true; mouse_x=x; mouse_y=y} (*mouse clicked*)
    -> print_endline ("Mouse pressed at (" ^ (string_of_int x) ^ ", " ^ (string_of_int y) ^ ")")
  | {mouse_x=x; mouse_y=y} (*mouse released*)
    -> print_endline ("Mouse released at (" ^ (string_of_int x) ^ ", " ^ (string_of_int y) ^ ")")

let rec listen_for_event () =
  let cur_status = wait_next_event [Button_down; Button_up; Key_pressed] in
  handle_event cur_status;
  listen_for_event ()

let main () = open_graph " 500x500";
  draw_rect 100 100 200 200;
  moveto 120 120;
  draw_string "hello world";
  set_color (rgb 128 128 128);
  fill_rect 150 150 150 150;
  set_color green;
  fill_rect 200 200 100 100;
  listen_for_event ();;

let () = main ()
