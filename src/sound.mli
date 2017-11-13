(* This module will create sound types with the specified
 * configurations and offer an abstraction for important sound
 * functions.
 *)

(* The sound type will contain the current state of the sound. *)
type sound

(* The options for a sound *)
type sound_options = {
  loop: bool;
  hold_to_play: bool;
  groups: int list;
  quantization: int; 
}

(* [get_next_value filenames options] create a sound with the given [options]
 * from [filenames] with pitches in the order given.
 *)
val create : string list -> sound_options -> sound option

(* [play_sound sound] tell the sound to play the next pitch *)
val play_sound : sound -> unit

(* [pause_sound sound] tell the sound to pause the current pitch *)
val pause_sound : sound -> unit

(* [stop_sound sound] tell the sound to stop the current pitch and reset the buffer *)
val stop_sound : sound -> unit

(* [next_pitch sound] sets the sound to the next pitch. Should be stopped *)
val next_pitch : sound -> unit

(* [get_next_values sound] get the next [(left,right)] values out of the
 * sound buffer. Will return (0,0) if the sound is done.
 *)
val get_next_values : sound -> int*int

(* [is_playing sound] returns true if the sound is playing *)
val is_playing : sound -> bool