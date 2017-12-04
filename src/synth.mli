(* The waveform of the synthesized sound *)
type waveform = Sine | Triangle | Saw | Square

(* The synthesized sound type *)
type synth

val create : waveform -> int*int -> synth

val start : synth -> unit

val get_next_sample : synth -> int*int

val is_equal :  int*int -> synth -> bool

val is_playing : synth -> bool

val release : synth -> unit