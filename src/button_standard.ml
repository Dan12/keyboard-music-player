(* This module will handle creation and use of buttons. *)

type point = int*int

type button = {
  mutable corner:point;
  mutable w:int;
  mutable h:int;
  on_down:point -> unit;
  on_up:point -> unit;
  mutable draw:(Tsdl.Sdl.renderer -> unit) option
}

(* create a button with the on down event, on up event, draw function *)
let create_button on_down on_up =
  {
    corner = (0, 0);
    w = -1;
    h = -1;
    on_down = on_down;
    on_up = on_up;
    draw = None
  }

let set_area b x y w h =
  b.corner <- (x, y);
  b.w <- w;
  b.h <- h

let get_area b =
  let b_x, b_y = b.corner in
  (b_x, b_y, b.w, b.h)

let contains b (x, y) =
  let b_x, b_y = b.corner in
  x >= b_x && y >= b_y && x <= (b_x + b.w) && y <= (b_y + b.h)

(* if the button contains the point, execute the pressed callback *)
let down_press b p =
  if contains b p
  then b.on_down p
  else ()


(* if the button contains the point, execute the released callback *)
let up_press b p =
  if contains b p
  then b.on_up p
  else ()


(* set the function to be executed when draw is called *)
let set_draw b draw =
  b.draw <- Some draw

(* execute the draw callback *)
let draw b =
  match b.draw with
  | Some d -> d
  | _ -> ignore
