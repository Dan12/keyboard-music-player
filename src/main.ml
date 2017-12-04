let tick_callback () =
  if Model.is_scrubbing() then
    let percent_played =
      (Model.get_scrub_pos() -. Model.get_scrub_pos_min())
      /. (Model.get_scrub_pos_max() -. Model.get_scrub_pos_min()) in
    let midi = Midi_player.get_midi() in
    let beat = Midi.length midi *. percent_played in
    Midi.scrub_to_beat midi beat;
    Metronome.set_beat beat;
  else
    if Model.midi_should_load() then
      Midi_player.set_midi (Model.get_midi_filename ());
    if Model.midi_is_playing() then
      Metronome.tick();
      let midi = Midi_player.get_midi () in
      let beat = Metronome.get_beat () in
      Midi.tick midi beat;

      let percent_played = beat /. (Midi.length midi) in
      let scrub_pos = percent_played *. (Model.get_scrub_pos_max() -. Model.get_scrub_pos_min())
                      +. Model.get_scrub_pos_min() in
      Model.set_scrub_pos scrub_pos;

      if Midi.is_done midi then
        Model.stop_midi()
in

Model.set_filename_buttons (Model.get_file_location ());
let window_width = Model.get_width () in
let window_height = Model.get_height () in
Tsdl_wrapper.init (window_width, window_height);

Tsdl_wrapper.set_draw_callback Gui.draw;
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;
Tsdl_wrapper.set_tick_callback tick_callback;

print_endline "starting";

Tsdl_wrapper.start_main_loop ();

print_endline "closed"
