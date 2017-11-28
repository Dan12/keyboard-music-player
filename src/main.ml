Sound_manager.init ();
let window_width = Model.get_width () in
let window_height = Model.get_height () in
Tsdl_wrapper.init (window_width, window_height);
print_endline "starting";

Tsdl_wrapper.set_draw_callback Gui.draw;
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;
Tsdl_wrapper.set_tick_callback Metronome.tick;

Tsdl_wrapper.start_main_loop ();

print_endline "closed"
