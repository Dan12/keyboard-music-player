(* This module will handle incoming user events and control the
 * output of data to the audio buffer. We have to be careful
 * because the audio callback runs on its own thread. So when
 * an event comes in, we will first acquire the audio callback
 * lock and then make updates to the internal state. This is
 * because the internal state will be entirely mutable.
 *)

(* [key_pressed (r,c)] callback when key is pressed on the keyboard
 * row [r] and column [c]
 *)
val key_pressed : int*int -> unit

(* [key_released (r,c)] callback when key is released on the keyboard
 * row [r] and column [c]
 *)
val key_released : int*int -> unit

(* [audio_callback output] is the audio callback that populates [output]
 * with audio data
 *)
val audio_callback : (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit