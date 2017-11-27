Sound_manager.init ();
let eq_song = Song.parse_song_file "resources/eq.json" in
Sound_manager.set_song eq_song;

let keyboard_layout = Keyboard_layout.parse_layout "resources/standard_keyboard_layout.json" in
let rows = Keyboard_layout.get_rows keyboard_layout in
let cols = Keyboard_layout.get_cols keyboard_layout in
let keyboard = Keyboard.create_keyboard (rows, cols) in
Input_event_manager.init keyboard keyboard_layout;

Tsdl_wrapper.init (1280,720);
print_endline "starting";

Tsdl_wrapper.set_draw_callback (Gui.draw keyboard_layout keyboard);
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;

State_manager.set_state State_manager.SKeyboard;
Tsdl_wrapper.start_main_loop ();

print_endline "closed"
