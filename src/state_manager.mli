(* This module will keep track of the state of the system *)

(* The different possible states. Input routing is determined
 * by which state the system is in.
 *)
type state = SKeyboard

(* [init] Initialize the state manager *)
val init : unit -> unit

(* [set_state state] set the state of the system *)
val set_state : state -> unit