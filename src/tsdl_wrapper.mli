(* This module will create convenient wrappers and abstraction for
 * initializing the Tsdl environment, making common draw calls,
 * registering event handlers, and loading and playing audio files
 *)


(* Holds tsdl state information across function applications *)
type tsdl_state

(* [init width,height] initializes a new tsdl state with a window of the given
 * [width] and [height] and a new audio context. This call will only succeed once.
 *)
val init : int*int -> unit

(* [quit] will clean up and close the Sdl context. Has no effect if called
 * before init.
 *)
val quit : unit -> unit

(* [set_draw_callback draw_fun] set the draw function to
 * be the specified function.
 *)
val set_draw_callback : (Tsdl.Sdl.renderer -> unit) -> unit

(* [set_draw_callback audio_fun] set the audio callback function to
 * be [audio_fun]
 *)
val set_audio_callback : ((int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit) -> unit

(* [set_event_callback event_fun] set the event function to
 * be [event_fun]
 *)
 val set_event_callback : (Tsdl.Sdl.event -> unit) -> unit

(* [load_wav filename] returns a buffer the is contents of [filename]
 * in wav format. If the file doesn't exist or there was a problem parsing
 * the file, return None
 *)
(* val load_wav : string -> (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray option *)