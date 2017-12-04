(* Tick the metronome. Update internal state based on time *)
val tick : unit -> unit

(* Sets the beats per minute *)
val set_bpm : int -> unit

(* Returns the current bpm. *)
val get_bpm : unit -> int

(* get the current beat/measure or something *)
val get_beat : unit -> float

(* [set_beat beat] sets the current beat/measure. *)
val set_beat : float -> unit

(* [unpause] restarts the metronome w/o resetting the beat. *)
val unpause : unit -> unit

(* reset the beat/measure *)
val reset : unit -> unit

(**
 * NOTE: When using this file for the first time, call functions in the
 * following order: reset(), set_bpm(), tick(), get_beat().
 * OR in this order: set_bpm(), reset(), tick(), get_beat().
 * But no other order, please.
 * Then call tick() every once in a while.
 *)
