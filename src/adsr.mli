(* asdr parameters *)
type adsr_t

(* state in the asdr *)
type adsr_state

(* [make_adsr sample_rate attack decay sustain release] creates a
 * new adsr envelope
 *)
val make_adsr : int -> float*float*float*float -> adsr_t

(* [init_state] sets up an initial asdr state *)
val init_state : unit -> adsr_state

(* [release_state state] set [state] to the release state *)
val release_state : adsr_state -> unit

(* [is_dead state] returns true if the state is in the dead state *)
val is_dead : adsr_state -> bool

(* [process_sample envelope state sample] returns the gain
 * adjusted mono [sample] based on the current [state] and
 * [envelope]
 *)
val process_sample : adsr_t -> adsr_state -> float -> float
