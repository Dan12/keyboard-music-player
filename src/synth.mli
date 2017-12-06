(* The waveform of the synthesized sound *)
type waveform = Sine | Triangle | Saw | Square

(* The synthesized sound type *)
type synth

(* [create waveform (octave,note)] create a new
 * synthesized sound with the given waveform at the given
 * [octave] and [note].
 *)
val create : waveform -> int*int -> synth

(* [start synth] starts the synth *)
val start : synth -> unit

(* [get_next_sample synth] returns the next mono sample
 * for the synth.
 *)
val get_next_sample : synth -> float

(* [is_equal (octave,note) synth] returns true if [synth]
 * is a synth for [octave] and [note] *)
val is_equal :  int*int -> synth -> bool

(* [is_playing synth] returns true if [synth] is still playing *)
val is_playing : synth -> bool

(* [release synth] sends the release signal to [synth] *)
val release : synth -> unit
