open Keyboard_layout
open Keyboard
(* This module will contain a draw call called by the Tsdl loop and
 * receive input events from the sound manager to update the draw state.
*)

(* [draw renderer] the draw callback that makes draw calls using
 * [renderer] to display the state.
 *)
val draw : Tsdl.Sdl.renderer -> unit

(* [button_pressed x y] returns the button that encloses the given
location if such button exists. *)
val button_pressed : (int * int) -> Button.button option

(* [file_button_pressed x y] returns the file button that encloses the given
location if such button exists. *)
val file_button_pressed : (int * int) -> File_button.file_button option

(* [filename_button_pressed x y] returns the filename button that encloses the
given location if such button exists. *)
val filename_button_pressed : (int * int) -> File_button.filename_button option

(* [scrub_pressed x y] returns whether or not the scrub was pressed. *)
val scrub_pressed : (int * int) -> bool
