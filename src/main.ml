Song.parse_song_file "eq.json";

Tsdl_wrapper.init (1280,720);
print_endline "starting";
Tsdl_wrapper.set_draw_callback Gui.draw;
Tsdl_wrapper.start_main_loop ();
print_endline "closed"
