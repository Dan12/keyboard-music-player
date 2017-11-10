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

val create_font : string -> int -> Tsdl_ttf.Ttf.font

val draw_text : string -> int*int -> Tsdl_ttf.Ttf.font -> tsdl_state -> unit

val measure_text : string -> Tsdl_ttf.Ttf.font -> tsdl_state -> int*int

val draw_rect : int*int*int*int -> tsdl_state -> unit

val set_color : Tsdl.Sdl.(uint8*uint8*uint8) -> tsdl_state -> unit

val set_draw_callback : (Tsdl.Sdl.renderer -> unit) -> tsdl_state -> unit

val set_audio_callback : ((int32, 'a, 'b) Bigarray.Array1.t -> unit) -> unit

val set_mouse_down_callback : (int*int -> unit) -> tsdl_state -> unit

val set_mouse_up_callback : (int*int -> unit) -> tsdl_state -> unit

val set_mouse_move_callback : (int*int -> unit) -> tsdl_state -> unit

val set_key_down_callback : (string -> unit) -> tsdl_state -> unit

val set_key_up_callback : (string -> unit) -> tsdl_state -> unit

val load_wav : string -> (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray option

val acquire_audio_lock : tsdl_state -> unit

val release_audio_lock : tsdl_state -> unit