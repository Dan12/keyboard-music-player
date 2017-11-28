Sound_manager.init ();

let song_file = "resources/eq_data/eq.json" in
let keyboard_file = "resources/standard_keyboard_layout.json" in

let window_w = 1280 in
let window_h = 720 in

let eq_song = Song.parse_song_file song_file in
Sound_manager.set_song eq_song;

let keyboard_layout = Keyboard_layout.parse_layout keyboard_file in
let rows = Keyboard_layout.get_rows keyboard_layout in
let cols = Keyboard_layout.get_cols keyboard_layout in
let keyboard = Keyboard.create_keyboard (rows, cols) in
Input_event_manager.init keyboard keyboard_layout;

Tsdl_wrapper.init (window_w, window_h);
print_endline "starting";

Tsdl_wrapper.set_draw_callback (Gui.draw (window_w, window_h) keyboard_layout keyboard);
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;
Tsdl_wrapper.set_tick_callback Metronome.tick;

State_manager.set_state State_manager.SKeyboard;
Tsdl_wrapper.start_main_loop ();

print_endline "closed"
