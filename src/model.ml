open Tsdl
open Keyboard
open Keyboard_layout
open Song

(* The possible states of the interface
 * The keyboard lets the user play songs
 * The file chooser lets a user choose a file
 * The synthesizer lets a user generate synthesized sounds
 *)
type state = SKeyboard | SFileChooser | SSynthesizer

(* The waveform of the synthesized sound *)
type waveform = Sine | Triangle | Saw | Square

(* The fft instance to use when computing fft on
 * the current audio buffer
 *)
let fft = ref (Fft.init 10)

type model = {
  window_w: int;
  window_h: int;
  mutable keyboard: keyboard;
  mutable keyboard_layout: keyboard_layout;
  mutable song: song;
  mutable state: state;
  mutable midi_buttons: Button_standard.button list;
  mutable current_midi_button: int;
  mutable file_buttons: Button_standard.button list;
  mutable filename_buttons : Button_standard.button list;
  mutable current_filename_button: int;
  mutable synth_button: Button_standard.button option;
  mutable synth_grid: Button_standard.button option;
  mutable synth_buttons : Button_standard.button list;
  mutable wave_buttons : Button_standard.button list;
  mutable play_button: Button_standard.button option;
  mutable selected_filename: string option;
  mutable file_location: string;
  mutable midi_filename: string;
  mutable should_load_midi: bool;
  mutable is_playing: bool;
  mutable bpm_pos: float;
  mutable bpm_scrubbing: bool;
  mutable scrubbing: bool;
  mutable scrub_pos: float;
  scrub_pos_min: float;
  scrub_pos_max: float;
  bpm_pos_min: float;
  bpm_pos_max: float;
  adsr_pos_min: float;
  adsr_pos_max: float;
  mutable a_sliding: bool;
  mutable d_sliding: bool;
  mutable s_sliding: bool;
  mutable r_sliding: bool;
  mutable buffer: Complex.t array;
  mutable playing_song : bool;
  mutable beats_in_midi: float;
  mutable adsr_params: float*float*float*float;
  mutable filter: Filter.filter_t;
  mutable current_filter: Filter.filter_kind*float*float;
  mutable current_waveform: waveform;
}

let keyboard_border_color = Sdl.Color.create 0 0 0 255
let keyboard_pressed_color = Sdl.Color.create 128 128 255 255

let key_background = Sdl.Color.create 255 255 255 220

let keyboard_text_color = Sdl.Color.create 0 0 0 255




let contains s1 s2 =
let size = String.length s1 in
let contain = ref false in
let i = ref 0 in
while !i < (String.length s2 - size + 1) && !contain = false do
  if String.sub s2 !i size = s1 then contain := true
  else i := !i + 1
done;
!contain


let get_filenames dir =
  let folder_list =
    if Sys.is_directory dir
    then Sys.readdir dir |> Array.to_list
    else [] in
  let data_list = List.fold_left
      (fun j s -> if contains "data" s
        then (dir ^ s ^ Filename.dir_sep)::j else j) [] folder_list in
  let filename_list = List.fold_left
      (fun j s -> if Sys.is_directory (s) then
          (Sys.readdir s |> Array.to_list)@j else j) [] data_list in
  let json_list = List.fold_left
      (fun j s -> if contains ".json" s
        then s::j else j) [] filename_list in
  List.sort (compare) json_list



let model:model =
  let window_w = 1280 in
  let bpm_margin = 80.0 in
  let scrub_margin = 160.0 in
  let eq_song = Song.parse_song_file "resources/eq_data/eq_song.json" in
  let keyboard_layout = Keyboard_layout.parse_layout
      "resources/standard_keyboard_layout.json" in
  let rows = Keyboard_layout.get_rows keyboard_layout in
  let cols = Keyboard_layout.get_cols keyboard_layout in
  let keyboard = Keyboard.create_keyboard (rows, cols) in
  let buffer = Array.make 1024 {Complex.re = 0.; Complex.im = 0.;} in
  {
    window_w = window_w;
    window_h = 720;
    keyboard = keyboard;
    keyboard_layout = keyboard_layout;
    song = eq_song;
    state = SKeyboard;
    midi_buttons = [];
    current_midi_button = 3;
    file_buttons = [];
    selected_filename = None;
    filename_buttons = [];
    current_filename_button = -1;
    synth_button = None;
    synth_grid = None;
    synth_buttons = [];
    wave_buttons = [];
    play_button = None;
    file_location = "resources/";
    midi_filename = "resources/eq_data/eq_0_midi.json";
    should_load_midi = true;
    is_playing = false;
    bpm_pos = bpm_margin;
    scrubbing = false;
    bpm_scrubbing = false;
    scrub_pos = scrub_margin;
    scrub_pos_min = scrub_margin;
    scrub_pos_max = (float_of_int window_w) -. scrub_margin;
    bpm_pos_min = bpm_margin;
    bpm_pos_max = (float_of_int (window_w / 3)) -. bpm_margin;
    adsr_pos_min = float_of_int window_w *. 7.0 /. 15.0;
    adsr_pos_max = float_of_int window_w *. 11.0 /. 15.0;
    a_sliding = false;
    d_sliding = false;
    s_sliding = false;
    r_sliding = false;
    buffer = buffer;
    playing_song = true;
    beats_in_midi = 0.0;
    adsr_params = (0.0, 0.0, 1.0, 0.0);
    filter = Filter.make 44100 Filter.FKNone 100.0 1.0;
    current_filter = Filter.FKNone, 100.0, 1.0;
    current_waveform = Sine;
  }

let get_width () =
  model.window_w

let get_height () =
  model.window_h

let set_keyboard k =
  model.keyboard <- k

let get_keyboard () =
  model.keyboard

let set_keyboard_layout kl =
  model.keyboard_layout <- kl

let get_keyboard_layout () =
  model.keyboard_layout

let set_song s =
  model.song <- s

let get_song () =
  model.song

let get_state () =
  model.state

let get_midi_buttons () =
  model.midi_buttons

let get_file_buttons () =
  model.file_buttons

let get_filter_buttons () =
  model.synth_buttons

let get_wave_buttons () =
  model.wave_buttons

let get_synth_button () =
  match model.synth_button with
  | Some b -> b
  | None -> failwith "synth_button not made"

let get_synth_grid () =
  match model.synth_grid with
  | Some b -> b
  | None -> failwith "synth_grid not made"

let get_play_button () =
  match model.play_button with
  | Some b -> b
  | None -> failwith "play_button not made"


let get_file_location () =
  model.file_location

let get_filename_buttons () =
  model.filename_buttons

let set_midi_filename f =
  model.midi_filename <- f

let get_midi_filename () =
  model.midi_filename

let start_midi () =
  if model.is_playing = false then
    Metronome.unpause();
    model.is_playing <- true;
  model.should_load_midi <- false

let pause_midi () =
  model.is_playing <- false

let stop_midi () =
  model.is_playing <- false;
  model.should_load_midi <- true;
  Metronome.reset();
  model.scrub_pos <- model.scrub_pos_min;
  Metronome.set_bpm (model.song |> Song.get_bpm);
  model.bpm_pos <- ((Metronome.get_percent() *.
              (model.bpm_pos_max -. model.bpm_pos_min)) +. model.bpm_pos_min);
  model.current_midi_button <- 3

let clear_keyboard () =
  let layout = get_keyboard_layout() in
  let keyboard = get_keyboard() in
  let rows = Keyboard_layout.get_rows layout in
  let cols = Keyboard_layout.get_cols layout in
  for row = 0 to rows - 1 do
    for col = 0 to cols - 1 do
      Keyboard.process_event (Keyboard_layout.KOKeyup (row, col)) keyboard |> ignore
    done;
  done

let set_state s =
  stop_midi ();
  clear_keyboard ();
  model.current_midi_button <- 3;
  model.current_filename_button <- -1;
  model.state <- s

let midi_is_playing () = model.is_playing

let midi_should_load () = model.should_load_midi

let set_bpm_pos p =
  model.bpm_pos <- p;
  let bpm_length = model.bpm_pos_max -. model.bpm_pos_min in
  let percent = (p -. model.bpm_pos_min) /. bpm_length in
  Metronome.set_bpm_by_percent (percent)

let get_bpm_pos () =
  model.bpm_pos

let set_bpm_scrubbing b =
  model.bpm_scrubbing <- b

let is_bpm_scrubbing () =
  model.bpm_scrubbing

let get_bpm_pos_min () =
  model.bpm_pos_min

let get_bpm_pos_max () =
  model.bpm_pos_max

let set_midi_load load = model.should_load_midi <- load

let set_scrubbing scrubbing =
  model.scrubbing <- scrubbing

let is_scrubbing () =
  model.scrubbing

let get_scrub_pos () =
  model.scrub_pos

let set_scrub_pos pos =
  model.scrub_pos <- pos

let get_scrub_pos_min () =
  model.scrub_pos_min

let get_scrub_pos_max () =
  model.scrub_pos_max

let get_beats () =
  model.beats_in_midi

let get_current_waveform () =
  model.current_waveform

let set_beats beats =
  model.beats_in_midi <- beats

let set_buffer b =
  let (left, _) = Fft.complex_create b in
  Fft.cosine left;
  if Bigarray.Array1.dim b = 1024 then
    fft := Fft.init 9
  else
    ();
  Fft.fft (!fft) left;
  model.buffer <- left

let get_buffer () =
  model.buffer

let remove_selected_filename () =
  model.selected_filename <- None

let get_selected_filename () = model.selected_filename

let set_selected_filename file =
  model.selected_filename <- Some file

let commit_selected_filename () =
  match get_selected_filename() with
  | Some name ->
    let index = String.index name '_' in
    let folder = String.sub name 0 index in
    if contains "midi" name then
      let _ = set_midi_filename ((get_file_location())^folder^"_data/"^name) in
      set_song (Song.parse_song_file ((get_file_location())^folder^"_data/"^folder^"_song.json"))
    else
      let _ = set_song (Song.parse_song_file ((get_file_location())^folder^"_data/"^name)) in
      set_midi_filename ((get_file_location())^folder^"_data/"^folder^"_0_midi.json")
  | None -> ()

let get_adsr_params () =
  model.adsr_params

let set_adsr_params p =
  model.adsr_params <- p

let get_adsr_pos_min () =
  model.adsr_pos_min

let get_adsr_pos_max () =
  model.adsr_pos_max

let set_a_sliding b =
  model.a_sliding <- b

let get_a_sliding () =
  model.a_sliding

let set_d_sliding b =
  model.d_sliding <- b

let get_d_sliding () =
  model.d_sliding

let set_s_sliding b =
  model.s_sliding <- b

let get_s_sliding () =
  model.s_sliding

let set_r_sliding b =
  model.r_sliding <- b

let get_r_sliding () =
  model.r_sliding

let get_filter () =
  model.filter

let set_filter_params p =
  model.current_filter <- p;
  let (filter_kind, filter_freq, filter_q) = p in
  model.filter <- Filter.make 44100 filter_kind filter_freq filter_q


let set_filename_buttons dir =
  let files = get_filenames dir in
  let string_to_button index str =
    let recent_click = ref 0.0 in
    let button_up _ =
      set_selected_filename str;
      model.current_filename_button <- index;
      let time = Unix.gettimeofday() in
      begin
        if time -. !recent_click < 0.3
        then
          begin
            commit_selected_filename();
            remove_selected_filename();
            set_state SKeyboard
          end
      end;
      recent_click := time in


    let button_draw b = fun r ->
      let (x, y, w, h) = Button_standard.get_area b in

      let state = if model.current_filename_button = index then KSDown else KSUp in
      Gui_utils.draw_key r x y w h keyboard_pressed_color key_background keyboard_border_color state;

      let font_size = w / 10 in
      Gui_utils.draw_text r (x + w / 2) (y + h / 2) font_size keyboard_text_color str in


    let button = Button_standard.create_button ignore button_up ignore in
    Button_standard.set_draw button (button_draw button);
    button in

  model.filename_buttons <- List.mapi string_to_button files

let create_midi_buttons () =
  let button_draw b is_current_down draw_icon = fun r ->
    let (x, y, w, h) = Button_standard.get_area b in

    let state = if is_current_down model.current_midi_button then KSDown else KSUp in
    Gui_utils.draw_key r x y w h keyboard_pressed_color key_background keyboard_border_color state;

    draw_icon r x y w h in


  let load_up _ =
    set_filename_buttons (get_file_location());
    model.current_midi_button <- 0;
    set_state SFileChooser in

  let load_drawer r x y w h =
    let font_size = 3 * w / 8 in
    Gui_utils.draw_text r (x + w/2) (y + h/2) font_size keyboard_text_color "Load" in

  let load = Button_standard.create_button ignore load_up ignore in
  let load_draw = button_draw load ((=) 0) load_drawer in
  Button_standard.set_draw load load_draw;


  let play_up _ =
    model.current_midi_button <- 1;
    start_midi() in

  let play = Button_standard.create_button ignore play_up ignore in
  let play_draw = button_draw play ((=) 1) Gui_utils.draw_play in
  Button_standard.set_draw play play_draw;


  let pause_up _ =
    model.current_midi_button <- 2;
    pause_midi() in

  let pause = Button_standard.create_button ignore pause_up ignore in
  let pause_draw = button_draw pause ((=) 2) Gui_utils.draw_pause in
  Button_standard.set_draw pause pause_draw;


  let stop_up _ =
    model.current_midi_button <- 3;
    stop_midi();
    clear_keyboard() in

  let stop = Button_standard.create_button ignore stop_up ignore in
  let stop_draw = button_draw stop ((=) 3) Gui_utils.draw_stop in
  Button_standard.set_draw stop stop_draw;
  [load; play; pause; stop]

let create_file_buttons () =
  let button_draw b text = fun r ->
    let (x, y, w, h) = Button_standard.get_area b in

    Gui_utils.draw_key r x (y + 2*h/5) w (h - 2*h/5) keyboard_pressed_color key_background keyboard_border_color KSUp;

    let font_size = w / 4 in
    Gui_utils.draw_text r (x + w/2) (y + 2*h/3) font_size keyboard_text_color text in


  let cancel_up _ =
    remove_selected_filename();
    set_state SKeyboard in

  let cancel = Button_standard.create_button ignore cancel_up ignore in
  let cancel_draw = button_draw cancel "Cancel" in
  Button_standard.set_draw cancel cancel_draw;


  let select_up _ =
    commit_selected_filename();
    remove_selected_filename();
    set_state SKeyboard  in

  let select = Button_standard.create_button ignore select_up ignore in
  let select_draw = button_draw select "Select" in
  Button_standard.set_draw select select_draw;
  [cancel; select]

let create_transition_button state text =
  let transition_draw b = fun r ->
    let (x, y, w, h) = Button_standard.get_area b in

    Gui_utils.draw_key r x y w h keyboard_pressed_color key_background keyboard_border_color KSUp;

    let font_size = w / 6 in
    Gui_utils.draw_text r (x + w/2) (y + h/2) font_size keyboard_text_color text in


  let transition_up _ =
    set_state state in

  let transition = Button_standard.create_button ignore transition_up ignore in
  let transition_draw = transition_draw transition in
  Button_standard.set_draw transition transition_draw;
  transition

let create_synth_grid () =
  let is_moving = ref false in
  let prev_x = ref 0.0 in
  let prev_y = ref 0.0 in

  let grid_draw b = fun r ->
    let (x, y, w, h) = Button_standard.get_area b in
    Gui_utils.draw_key r x y w h keyboard_pressed_color key_background keyboard_border_color KSUp;

    let pressed_x = x + int_of_float ((float_of_int w) *. !prev_x) in
    let pressed_y = y + int_of_float ((float_of_int h) *. !prev_y) in

    let _ = Tsdl.Sdl.render_draw_line r (pressed_x - 5) pressed_y (pressed_x + 5) pressed_y in
    let _ = Tsdl.Sdl.render_draw_line r pressed_x (pressed_y - 5) pressed_x (pressed_y + 5) in
    () in


  let set_params (x, y) =
    prev_x := x;
    prev_y := y;
    let slope = 4.301029995664 -. 2.0 in
    (* 100 -- 20000 = 10^2 -- 10^4.301303 *)
    let x_scaled = 10.0 ** (x *. slope +. 2.0) in
    let y_scaled = ((1.0 -. y) *. 9.9) +. 0.1 in

    let filter, _, _ = model.current_filter in
    set_filter_params (filter, x_scaled, y_scaled) in

  let grid_down p =
    is_moving := true;
    set_params p in

  let grid_up p =
    if !is_moving then set_params p;
    is_moving := false in

  let grid_move p =
    if !is_moving then set_params p in

  let grid = Button_standard.create_button grid_down grid_up grid_move in
  let grid_draw = grid_draw grid in
  Button_standard.set_draw grid grid_draw;
  grid

let create_synth_buttons () =
  let count = ref 1 in
  let pressed = ref 5 in

  let button_draw b text =
    let button_id = !count in
    fun r ->
      let (x, y, w, h) = Button_standard.get_area b in

      let state = if !pressed = button_id then KSDown else KSUp in
      Gui_utils.draw_key r x y w h keyboard_pressed_color key_background keyboard_border_color state;

      let font_size = w / 7 in
      Gui_utils.draw_text r (x + w/2) (y + h/2) font_size keyboard_text_color text in

  let on_up filter =
    let button_id = !count in
    fun _ ->
      pressed := button_id;
      let _, x, y = model.current_filter in
      set_filter_params (filter, x, y) in


  let make_button filter text =
    let button_up = on_up filter in
    let button = Button_standard.create_button ignore button_up ignore in
    let my_button_draw = button_draw button text in
    Button_standard.set_draw button my_button_draw;
    count := !count + 1;
    button in

  let high = make_button Filter.FKHigh_pass "High Pass" in
  let low = make_button Filter.FKLow_pass "Low Pass" in
  let band = make_button Filter.FKBand_pass "Band Pass" in
  let notch = make_button Filter.FKNotch "Notch" in
  let none = make_button Filter.FKNone "None" in
  [high; low; band; notch; none]

let create_waveform_buttons () =
  let count = ref 1 in
  let pressed = ref 1 in

  let button_draw b text =
    let button_id = !count in
    fun r ->
      let (x, y, w, h) = Button_standard.get_area b in

      let state = if !pressed = button_id then KSDown else KSUp in
      Gui_utils.draw_key r x y w h keyboard_pressed_color key_background keyboard_border_color state;

      let font_size = w / 7 in
      Gui_utils.draw_text r (x + w/2) (y + h/2) font_size keyboard_text_color text in

  let on_up wave =
    let button_id = !count in
    fun _ ->
      pressed := button_id;
      model.current_waveform <- wave in


  let make_button wave text =
    let button_up = on_up wave in
    let button = Button_standard.create_button ignore button_up ignore in
    let my_button_draw = button_draw button text in
    Button_standard.set_draw button my_button_draw;
    count := !count + 1;
    button in

  let sine = make_button Sine "Sine Wave" in
  let triangle = make_button  Triangle "Triangle Wave" in
  let saw = make_button Saw "Saw Wave" in
  let square = make_button Square "Square Wave" in
  [sine; triangle; saw; square]



let _ = set_filename_buttons (get_file_location())
let _ = model.midi_buttons <- create_midi_buttons()
let _ = model.file_buttons <- create_file_buttons()
let _ = model.synth_button <-
    Some (create_transition_button SSynthesizer "Synthesize")
let _ = model.play_button <-
    Some (create_transition_button SKeyboard "Play")
let _ = model.synth_grid <- Some (create_synth_grid ())
let _ = model.synth_buttons <- create_synth_buttons ()
let _ = model.wave_buttons <- create_waveform_buttons()
