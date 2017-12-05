(* This module will contain a draw call called by the Tsdl loop and
 * receive input events from the sound manager to update the draw state.
*)

(* [draw renderer] the draw callback that makes draw calls using
 * [renderer] to display the state.
 *)
val draw : Tsdl.Sdl.renderer -> unit

(* [scrub_pressed x y] returns whether or not the scrub was pressed. *)
val scrub_pressed : (int * int) -> string -> bool
