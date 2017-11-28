Sound_manager.init ();

Tsdl_wrapper.init (1280,720);
print_endline "starting";

let keyboard = Model.get_keyboard () in
let keyboard_layout = Model.get_keyboard_layout () in

Tsdl_wrapper.set_draw_callback (Gui.draw keyboard_layout keyboard);
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;
Tsdl_wrapper.set_tick_callback Metronome.tick;

Tsdl_wrapper.start_main_loop ();

print_endline "closed"
