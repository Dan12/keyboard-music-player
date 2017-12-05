open Tsdl
open Keyboard
open Keyboard_layout
open Song

type state = SKeyboard | SFileChooser

let fft = ref (Audio_effects.init 10)

type model = {
  mutable window_w: int;
  mutable window_h: int;
  mutable keyboard: keyboard;
  mutable keyboard_layout: keyboard_layout;
  mutable song: song;
  mutable state: state;
  mutable midi_buttons: Button_standard.button list;
  mutable current_midi_button: int;
  mutable file_buttons: Button_standard.button list;
  mutable filename_buttons : Button_standard.button list;
  mutable current_filename_button: int;
  mutable selected_filename: string option;
  mutable file_location: string;
  mutable midi_filename: string;
  mutable should_load_midi: bool;
  mutable is_playing: bool;
  mutable buffer: Complex.t array;
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
  let eq_song = Song.parse_song_file "resources/eq_data/eq_song.json" in
  let keyboard_layout = Keyboard_layout.parse_layout
      "resources/standard_keyboard_layout.json" in
  let rows = Keyboard_layout.get_rows keyboard_layout in
  let cols = Keyboard_layout.get_cols keyboard_layout in
  let keyboard = Keyboard.create_keyboard (rows, cols) in
  let buffer = Array.make 1024 {Complex.re = 0.; Complex.im = 0.;} in
  {
    window_w = 1280;
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
    file_location = "resources/";
    midi_filename = "resources/eq_data/eq_0_midi.json";
    should_load_midi = true;
    is_playing = false;
    buffer = buffer;
  }

let set_width w =
  model.window_w <- w

let get_width () =
  model.window_w

let set_height h =
  model.window_h <- h

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
    Metronome.set_bpm (get_song() |> Song.get_bpm);
    model.is_playing <- true;
  model.should_load_midi <- false

let pause_midi () =
  model.is_playing <- false

let stop_midi () =
  model.is_playing <- false;
  model.should_load_midi <- true;
  Metronome.reset()

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

let set_buffer b =
  let (left, _) = Audio_effects.complex_create b in
  Audio_effects.cosine left;
  if Bigarray.Array1.dim b = 1024 then
    fft := Audio_effects.init 9
  else
    ();
  Audio_effects.fft (!fft) left;
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
      set_midi_filename ((get_file_location())^folder^"_data/"^name)
    else set_song (Song.parse_song_file ((get_file_location())^folder^"_data/"^name))
  | None -> ()



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


    let button = Button_standard.create_button ignore button_up in
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

  let load = Button_standard.create_button ignore load_up in
  let load_draw = button_draw load ((=) 0) load_drawer in
  Button_standard.set_draw load load_draw;


  let play_up _ =
    model.current_midi_button <- 1;
    start_midi() in

  let play = Button_standard.create_button ignore play_up in
  let play_draw = button_draw play ((=) 1) Gui_utils.draw_play in
  Button_standard.set_draw play play_draw;


  let pause_up _ =
    model.current_midi_button <- 2;
    pause_midi() in

  let pause = Button_standard.create_button ignore pause_up in
  let pause_draw = button_draw pause ((=) 2) Gui_utils.draw_pause in
  Button_standard.set_draw pause pause_draw;


  let stop_up _ =
    model.current_midi_button <- 3;
    stop_midi();
    clear_keyboard() in

  let stop = Button_standard.create_button ignore stop_up in
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

  let cancel = Button_standard.create_button ignore cancel_up in
  let cancel_draw = button_draw cancel "Cancel" in
  Button_standard.set_draw cancel cancel_draw;


  let select_up _ =
    commit_selected_filename();
    remove_selected_filename();
    set_state SKeyboard  in

  let select = Button_standard.create_button ignore select_up in
  let select_draw = button_draw select "Select" in
  Button_standard.set_draw select select_draw;
  [cancel; select]



let _ = set_filename_buttons (get_file_location())
let _ = model.midi_buttons <- create_midi_buttons()
let _ = model.file_buttons <- create_file_buttons()
