(* This module will handle creation and use of buttons. *)

(* represents a button, a button is a recangular surface mapped with events  *)
type button

(* represents a point (x, y) with ints *)
type ipoint = int*int
(* represents a point (x, y) with floats *)
type fpoint = float*float


(* create a button with the on down event, on up event, and on move event *)
val create_button : (fpoint -> unit) -> (fpoint -> unit) -> (fpoint -> unit) -> button

(* move the button to the x, y, width, height *)
val set_area : button -> int -> int -> int -> int -> unit

(* get the current upper left point, width, and height *)
val get_area : button -> int*int*int*int

(* if the button contains the point, execute the pressed callback *)
val down_press : button -> ipoint -> unit

(* if the button contains the point, execute the released callback *)
val up_press : button -> ipoint -> unit

(* if the button contains the point, execute the moved callback *)
val on_move : button -> ipoint -> unit

(* set the function to be executed when draw is called *)
val set_draw : button -> (Tsdl.Sdl.renderer -> unit) -> unit

(* execute the draw callback *)
val draw : button -> Tsdl.Sdl.renderer -> unit
