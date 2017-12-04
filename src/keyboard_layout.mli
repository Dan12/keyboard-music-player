(* This module will handle the loading of the keyboard configuration
 * file and the mapping of keyboard keys to sound positions.
 *)

(* This type is a parse keyboard layout *)
type keyboard_layout

(* This is the type of possible outputs from a layout
 *)
type keyboard_output =
  | KOKeydown of int*int
  | KOKeyup of int*int
  | KOSoundpackSet of int
  | KOUnmapped
  | KOSpace

(* This is the type of possible inputs to a layout*)
type keyboard_input =
  | KIKeydown of int
  | KIKeyup of int

(* These keys are the different possible visuals to add to each key *)
type key_visual =
  | String of string
  | Shift
  | Enter
  | Empty

(* [parse_layout filename] parses [filename] into a keyboard layout *)
val parse_layout : string -> keyboard_layout

(* [process_key char is_key_down layout] uses [layout] to transform [char]
 * and [is_key_down] to a keyboard output type to be processed later
 *)
val process_key : keyboard_input -> keyboard_layout -> keyboard_output

(* [get_rows layout] returns the number of rows of keys *)
val get_rows : keyboard_layout -> int

(* [get_rows layout] returns the number of columns of keys*)
val get_cols : keyboard_layout -> int

(* [get_key (r,c) keyboard] returns the visual key mapping of the key at the given
 * row and column.
 *)
val get_visual : int*int -> keyboard_layout -> key_visual
