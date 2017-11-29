(* This module will handle the buttons for the midi player. *)

type button =
  | Load
  | Play
  | Pause
  | Stop

type buttons = (button * Keyboard.key_state) array

(* [buttons] returns the list of all variant types above with their state. *)
val create_buttons : unit -> buttons

(* [num_buttons] returns the number of variant types above. *)
val num_buttons : int

(* [press_button button buttons] sets the button within the buttons array to
   key down. *)
val press_button : button -> buttons -> unit
