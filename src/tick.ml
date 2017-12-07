let tick () =
  (* Set midi & bpm so Metronome can use it if we scrub before pressing play. *)
  (* Loading must be first, since it starts up the metronome with the correct values. *)
  if Model.midi_should_load() then
    begin
      Midi_player.set_midi (Model.get_midi_filename ());
      Metronome.set_bpm (Model.get_song() |> Song.get_bpm);
      Midi_player.get_midi() |> Midi.length |> Model.set_beats;
      Model.set_midi_load false
    end;
  let midi = Midi_player.get_midi () in
  (* If scrubbing, change the beat *)
  if Model.is_scrubbing() then
    begin
      let percent_played =
        (Model.get_scrub_pos() -. Model.get_scrub_pos_min())
        /. (Model.get_scrub_pos_max() -. Model.get_scrub_pos_min()) in
      let beat = Midi.length midi *. percent_played in
      Midi.scrub_to_beat midi beat;
      Metronome.set_beat beat
    end
  (* if not scrubbing, play/stop depending on current state *)
  else
    begin
      if Midi.is_done midi then
        begin
          Model.stop_midi();
          Input_event_manager.clear_keyboard()
        end;
      if Model.midi_is_playing() then
        begin
          Metronome.tick();
          let beat = Metronome.get_beat () in
          Midi.tick midi beat;
          (* update the scrub as the midi plays *)
          let percent_played = beat /. (Midi.length midi) in
          let scrub_pos = percent_played *. (Model.get_scrub_pos_max() -. Model.get_scrub_pos_min())
                          +. Model.get_scrub_pos_min() in
          Model.set_scrub_pos scrub_pos
        end
    end
