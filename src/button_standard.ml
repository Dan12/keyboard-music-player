(* This module will handle creation and use of buttons. *)

type ipoint = int*int
type fpoint = float*float

type button = {
  mutable corner:ipoint;
  mutable w:int;
  mutable h:int;
  on_down:fpoint -> unit;
  on_up:fpoint -> unit;
  moved_at:fpoint -> unit;
  mutable draw:(Tsdl.Sdl.renderer -> unit) option
}

(* create a button with the on down event, on up event, draw function *)
let create_button on_down on_up moved_at =
  {
    corner = (0, 0);
    w = -1;
    h = -1;
    on_down = on_down;
    on_up = on_up;
    moved_at = moved_at;
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

let convert_to_local_coords b (x, y) =
  let b_x, b_y = b.corner in
  let f_x = float_of_int (x - b_x) in
  let f_y = float_of_int (y - b_y) in
  let f_w = float_of_int b.w in
  let f_h = float_of_int b.h in
  f_x /. f_w, f_y /. f_h

(* if the button contains the point, execute the pressed callback *)
let down_press b p =
  if contains b p
  then b.on_down (convert_to_local_coords b p)
  else ()


(* if the button contains the point, execute the released callback *)
let up_press b p =
  if contains b p
  then b.on_up (convert_to_local_coords b p)
  else ()


(* if the button contains the point, execute the moved callback *)
let on_move b p =
  if contains b p
  then b.moved_at (convert_to_local_coords b p)
  else ()


(* set the function to be executed when draw is called *)
let set_draw b draw =
  b.draw <- Some draw

(* execute the draw callback *)
let draw b =
  match b.draw with
  | Some d -> d
  | _ -> ignore
