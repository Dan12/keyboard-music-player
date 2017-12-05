(* The input event manager contains the event callback in order to parse
 * incoming events and route then to the correct manager based on the
 * state.
 *)

(* [event_callback event] gets called whenever an event is registered.
 * This will parse the event and route it to the appropriate function
 * depending on the state.
 *)
val event_callback : Tsdl.Sdl.event -> unit

(* [handle_keyboard_output output] processes the keyboard_output and alerts
   the soundmanager (to play sounds) and the keyboard (to show key presses). *)
val handle_keyboard_output : Keyboard_layout.keyboard_output -> unit

(* [clear_keyboard] resets all the keys on the keyboard to their default
   states. *)
val clear_keyboard : unit -> unit
