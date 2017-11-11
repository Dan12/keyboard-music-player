(* This module will create convenient wrappers and abstraction for
 * initializing the Tsdl environment, making common draw calls,
 * registering event handlers, and loading and playing audio files
 *)


(* Holds tsdl state information across function applications *)
type tsdl_state

(* [init width height] create a new tsdl state with a window of the given
 * [width] and [height] and a new audio context.
 *)
val init : int -> int -> tsdl_state

(* [set_draw_callback draw_fun state] set [state]'s draw function to
 * be the specified function.
 *)
val set_draw_callback : (Tsdl.Sdl.renderer -> unit) -> tsdl_state -> unit

(* [set_draw_callback draw_fun state] set [state]'s draw function to
 * be [draw_fun]
 *)
val set_audio_callback : ((int32, 'a, 'b) Bigarray.Array1.t -> unit) -> unit

(* [set_mouse_down_callback mouse_down state] set [state]'s mouse down
 * callback to be [mouse_down]
 *)
val set_mouse_down_callback : (int*int -> unit) -> tsdl_state -> unit

(* [set_mouse_up_callback mouse_up state] set [state]'s mouse up
 * callback to be [mouse_up]
 *)
val set_mouse_up_callback : (int*int -> unit) -> tsdl_state -> unit

(* [set_mouse_move_callback mouse_move state] set [state]'s mouse move
 * callback to be [mouse_move]
 *)
val set_mouse_move_callback : (int*int -> unit) -> tsdl_state -> unit

(* [set_key_down_callback key_down state] set [state]'s key down
 * callback to be [key_down]
 *)
val set_key_down_callback : (string -> unit) -> tsdl_state -> unit

(* [set_key_up_callback key_up state] set [state]'s key up
 * callback to be [key_up]
 *)
val set_key_up_callback : (string -> unit) -> tsdl_state -> unit

(* [load_wav filename] returns a buffer the is contents of [filename]
 * in wav format. If the file doesn't exist or there was a problem parsing
 * the file, return None
 *)
val load_wav : string -> (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray option

(* [acquire_audio_lock state] acquire the lock for [state]'s primary
 * audio device. While the lock is acquired, the audio callback will block,
 * so only acquire the lock around quick sections of code, otherwise the
 * audio will sound laggy.
 *)
val acquire_audio_lock : tsdl_state -> unit

(* [release_audio_lock state] release the lock for [state]'s audio device.
 * Critical section code should always be wrapped with a pair of acquire,
 * release statements.
 *)
val release_audio_lock : tsdl_state -> unit