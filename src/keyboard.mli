
type keyboard

type key_state = 
  | KSDown
  | KSUp

val init : int*int -> keyboard

val process_event : Keyboard_layout.keyboard_input -> keyboard -> bool

val get_state : int*int -> keyboard -> key_state