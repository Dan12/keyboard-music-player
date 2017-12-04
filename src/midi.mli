type midi

(* [empty] returns a midi with nothing to play and no name for midi_player
to initialize with. *)
val empty : midi

(* [parse_midi filename] parses [filename] into a midi *)
val parse_midi : string -> midi

(* [tick midi beat] plays the notes that have passed in the midi since beat,
   calling key_pressed, key_released, and set_soundpack. *)
val tick : midi -> float -> unit

(* [is_done midi] returns whether or not the midi is done playing. *)
val is_done : midi -> bool
