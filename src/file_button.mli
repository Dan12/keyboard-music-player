(* This module will handle buttons for the filechooser. *)

type file_button =
  | Cancel
  | Select

type file_buttons = file_button array

(* [num_file_buttons] returns the number of file_button types. *)
val num_file_buttons : int

(* [create_file_buttons] returns an array of the all the file_button types. *)
val create_file_buttons : unit -> file_buttons
