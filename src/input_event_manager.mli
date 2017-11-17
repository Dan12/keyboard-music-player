(* The input event manager contains the event callback in order to parse
 * incoming events and route then to the correct manager based on the
 * state.
 *)

(* [init keyboard keyboard_layout] Initialize the input manager
 * with [keyboad] and [keyboard_layout]
 *)
val init : Keyboard.keyboard -> Keyboard_layout.keyboard_layout -> unit

(* [event_callback event] gets called whenever an event is registered.
 * This will parse the event and route it to the appropriate function
 * depending on the state.
 *)
val event_callback : Tsdl.Sdl.event -> unit