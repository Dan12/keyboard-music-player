(* Initialize some data *)
Metronome.set_bpm (Model.get_song() |> Song.get_bpm);
Model.set_bpm_pos ((Metronome.get_percent() *. (Model.get_bpm_pos_max() -. Model.get_bpm_pos_min())) +. Model.get_bpm_pos_min());
Model.set_filename_buttons (Model.get_file_location ());

(* Initialize the Tsdl_wrapper *)
let window_width = Model.get_width () in
let window_height = Model.get_height () in
Tsdl_wrapper.init (window_width, window_height);

(* Set the Tsdl_wrapper callbacks *)
Tsdl_wrapper.set_draw_callback Gui.draw;
Tsdl_wrapper.set_audio_callback Sound_manager.audio_callback;
Tsdl_wrapper.set_event_callback Input_event_manager.event_callback;
Tsdl_wrapper.set_tick_callback Tick.tick;

(* Start the Tsdl_wrapper main loop. This function returns when the user
 * closes the window or if an error occurs.
 *)
Tsdl_wrapper.start_main_loop ();
