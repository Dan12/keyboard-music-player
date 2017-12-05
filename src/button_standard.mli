(* This module will handle creation and use of buttons. *)

type button

type point = int*int

(* create a button with the on down event, on up event *)
val create_button : (point -> unit) -> (point -> unit) -> button

(* move the button to the x, y, width, height *)
val set_area : button -> int -> int -> int -> int -> unit

(* get the current upper left point, width, and height *)
val get_area : button -> int*int*int*int

(* if the button contains the point, execute the pressed callback *)
val down_press : button -> point -> unit

(* if the button contains the point, execute the released callback *)
val up_press : button -> point -> unit

(* set the function to be executed when draw is called *)
val set_draw : button -> (Tsdl.Sdl.renderer -> unit) -> unit

(* execute the draw callback *)
val draw : button -> Tsdl.Sdl.renderer -> unit
