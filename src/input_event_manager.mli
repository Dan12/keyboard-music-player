(* The input event manager contains the event callback in order to parse
 * incoming events and route then to the correct manager based on the
 * state.
 *)

(* [init] Initialize the input manager *)
val init : unit -> unit

(* [event_callback event] gets called whenever an event is registered.
 * This will parse the event and route it to the appropriate function
 * depending on the state.
 *)
val event_callback : Tsdl.Sdl.event -> unit