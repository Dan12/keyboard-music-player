open Sys
(* This module will handle buttons for the filechooser. *)

type filename_button = string

type file_button =
  | Cancel
  | Select

type filename_buttons = (filename_button * Keyboard.key_state) array

type file_buttons = file_button array

(* [num_file_buttons] returns the number of file_button types. *)
val num_file_buttons : int

(* [create_file_buttons] returns an array of the all the file_button types. *)
val create_file_buttons : unit -> file_buttons

(* [create_empty_filename_list] returns an empty array of filename_buttons. *)
val create_empty_filename_list : unit -> filename_buttons

(* [create_filename_buttons f] returns an array of filename_buttons in
   directory [f]. *)
val create_filename_buttons : string -> filename_buttons

(* [press_filename_button file buttons] marks [file] in [buttons] as currently
   selected. *)
val press_filename_button : filename_button -> filename_buttons -> unit

(* [selected_filename buttons] returns either the currently selected filename
   or None if no filename is currently selected. *)
val selected_filename : filename_buttons -> filename_button option
