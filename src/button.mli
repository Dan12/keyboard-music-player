(* This module will handle the buttons for the midi player. *)

type button =
  | Load
  | Play
  | Pause

(* [buttons] returns the list of all variant types above. *)
val buttons : button list

(* [get_location button] returns the x y width height of the given button. *)
val get_location : button -> int * int * int * int

(* [get_button x y] returns the button at the given location if the given
location is within a button. *)
val get_button : int * int -> button option
