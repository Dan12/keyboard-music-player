(* This module will handle incoming user events and control the
 * output of data to the audio buffer. We have to be careful
 * because the audio callback runs on its own thread. So when
 * an event comes in, we will first acquire the audio callback
 * lock and then make updates to the internal state. This is
 * because the internal state will be entirely mutable.
 *)

type sound_manager

type sound_state = SSPressed | SSReleased

val init : unit -> sound_manager

val set_song : Song.song -> sound_manager -> unit

(* [get_drawable_state sound_manager] returns the state of the current song
 * as a 2D list of sound states and a sound_pack number
 *)
val get_drawable_state : sound_manager -> sound_state list list*int