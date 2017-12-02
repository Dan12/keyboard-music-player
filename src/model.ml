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
  buttons: Button.buttons;
  file_buttons: File_button.file_buttons;
  mutable filename_buttons : File_button.filename_buttons;
  mutable num_filename_buttons : int;
  mutable file_location: string;
  mutable midi_filename: string;
  mutable should_load_midi: bool;
  mutable is_playing: bool;
  mutable buffer: Complex.t array;
}

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
    buttons = Button.create_buttons();
    file_buttons = File_button.create_file_buttons();
    filename_buttons = File_button.create_empty_filename_list ();
    num_filename_buttons = 0;
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

let set_state s =
  model.state <- s

let get_state () =
  model.state

let get_buttons () =
  model.buttons

let get_file_buttons () =
  model.file_buttons

let get_file_location () =
  model.file_location

let set_filename_buttons d =
  model.filename_buttons <-
    File_button.create_filename_buttons (get_file_location ())

let get_filename_buttons () =
  model.filename_buttons

let get_num_filename_buttons () =
  model.num_filename_buttons <- Array.length (get_filename_buttons ());
  model.num_filename_buttons

let set_midi_filename f =
  model.midi_filename <- f

let get_midi_filename () =
  model.midi_filename

let start_midi () =
  if model.is_playing = false then
    Metronome.unpause();
    Metronome.set_bpm (get_song() |> Song.get_bpm);
    model.is_playing <- true;
  model.should_load_midi <- false;
  Button.press_button Button.Play model.buttons

let pause_midi () =
  model.is_playing <- false;
  Button.press_button Button.Pause model.buttons

let stop_midi () =
  model.is_playing <- false;
  model.should_load_midi <- true;
  Metronome.reset();
  Button.press_button Button.Stop model.buttons

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
