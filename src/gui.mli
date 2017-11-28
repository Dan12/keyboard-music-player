open Keyboard_layout
open Keyboard
(* This module will contain a draw call called by the Tsdl loop and
 * receive input events from the sound manager to update the draw state.
*)

(* [draw renderer] the draw callback that makes draw calls using
 * [renderer] to display the state.
 *)
val draw : int*int -> keyboard_layout -> keyboard -> Tsdl.Sdl.renderer -> unit
