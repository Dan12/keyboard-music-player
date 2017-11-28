open Keyboard_layout
open Keyboard
(* This module will contain a draw call called by the Tsdl loop and
 * receive input events from the sound manager to update the draw state.
*)

(* [draw renderer] the draw callback that makes draw calls using
 * [renderer] to display the state.
 *)
val draw : keyboard_layout -> keyboard -> Tsdl.Sdl.renderer -> unit

(* [button_pressed x y] returns the button that encloses the given
location if such button exists. *)
val button_pressed : (int * int) -> Button.button option
