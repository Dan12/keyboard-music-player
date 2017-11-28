(* [set_midi filename] sets a new midi file to start playing. *)
val set_midi : string -> unit
(* [get_midi] returns the saved midi. Empty if [set_midi] was never called. *)
val get_midi : unit -> Midi.midi
