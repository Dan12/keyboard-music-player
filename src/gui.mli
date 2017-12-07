(* This module will contain a draw call called by the Tsdl loop. This model
 * will draw the window depending on the model's window state.
 *)

(* [draw renderer] the draw callback that makes draw calls using
 * [renderer] to display the state.
 *)
val draw : Tsdl.Sdl.renderer -> unit

(* [scrub_pressed x y] returns whether or not the scrub was pressed. *)
val scrub_pressed : (int * int) -> string -> bool
