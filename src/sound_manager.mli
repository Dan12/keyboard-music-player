(* This module will handle incoming user events and control the
 * output of data to the audio buffer. We have to be careful
 * because the audio callback runs on its own thread. So when
 * an event comes in, we will first acquire the audio callback
 * lock and then make updates to the internal state. This is
 * because the internal state will be entirely mutable.
 *)

val init : unit -> unit

val set_song : Song.song -> unit

val key_pressed : int*int -> unit

val key_released : int*int -> unit

val audio_callback : (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit