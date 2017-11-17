(* This module will store the state of the keyboard *)

(* This keyboard type will mainitain the state *)
type keyboard

(* These states are the various states a key can be in *)
type key_state =
  | KSDown
  | KSUp

(* These keys are the different possible visuals to add to each key *)
type key_visual =
  | String of string
  | Shift
  | Enter
  | Empty

(* [create_keyboard (r,c)] initializes a keyboard with [r] rows and
 * and [c] cols with all keys in the [KSUp] state.
 *)
val create_keyboard : int*int -> keyboard

(* [process_event input keyboard] modifies [keyboard]'s internal
 * state based on [input]. If [input] does not modify [keyboard]'s
 * state, return false. Otherwise, return true.
 *)
val process_event : Keyboard_layout.keyboard_output -> keyboard -> bool

(* [get_state (r,c) keyboard] returns the state of the key at the given
 * row and column.
 *)
val get_state : int*int -> keyboard -> key_state

(* [get_key (r,c) keyboard] returns the visual key mapping of the key at the given
 * row and column.
 *)
val get_visual : int*int -> keyboard -> key_visual
