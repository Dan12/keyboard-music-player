let tick_callback () =
  if Model.midi_should_load() then
    Midi_player.set_midi (Model.get_midi_filename ());
  if Model.midi_is_playing() then
    Metronome.tick ();
    let midi = Midi_player.get_midi () in
    let beat = Metronome.get_beat () in
    Midi.tick midi beat
in

Sound_manager.init ();

let window_width = Model.get_width () in
let window_height = Model.get_height () in
Tsdl_wrapper.init (window_width, window_height);
print_endline "starting";

let keyboard = Model.get_keyboard () in
let keyboard_layout = Model.get_keyboard_layout () in

Tsdl_wrapper.set_draw_callback (Gui.draw keyboard_layout keyboard);
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;
Tsdl_wrapper.set_tick_callback tick_callback;

Tsdl_wrapper.start_main_loop ();

print_endline "closed"
