(* This module will handle the buttons for the midi player. *)

type button =
  | Load
  | Play
  | Pause

(* [buttons] returns the list of all variant types above. *)
val buttons : button list
