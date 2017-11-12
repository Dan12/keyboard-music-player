(* This module will handle the loading of the keyboard configuration
 * file and the mapping of keyboard keys to sound positions.
 *)

type keyboard_layout

type keyboard_output = 
  | KOKeydown of int*int
  | KOKeyup of int*int
  | KOSoundpackSet of int
  | KOUnmapped

type keyboard_input = 
  | KIKeydown of int
  | KIKeyup of int

(* [parse_layout filename] parses [filename] into a keyboard layout *)
val parse_layout : string -> keyboard_layout

(* [process_key char is_key_down layout] uses [layout] to transform [char]
 * and [is_key_down] to a keyboard output type to be processed later
 *)
val process_key : keyboard_input -> keyboard_layout -> keyboard_output