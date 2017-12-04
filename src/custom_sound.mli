type waveform = Sine | Triangle | Saw | Square

type custom_sound

val create : waveform -> int*int -> custom_sound

val start : custom_sound -> unit

val get_next_sample : custom_sound -> int*int

val is_equal :  int*int -> custom_sound -> bool

val is_playing : custom_sound -> bool

val release : custom_sound -> unit