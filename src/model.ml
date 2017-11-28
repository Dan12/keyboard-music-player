open Keyboard
open Keyboard_layout
open Song

type state = SKeyboard | SFileChooser

type model = {
  mutable window_w: int;
  mutable window_h: int;
  mutable keyboard: keyboard;
  mutable keyboard_layout: keyboard_layout;
  mutable song: song;
  mutable state: state;
  mutable midi_filename: string;
  mutable should_load_midi: bool;
  mutable is_playing: bool;
}

let model:model =
  let eq_song = Song.parse_song_file "resources/eq_data/eq.json" in
  let keyboard_layout = Keyboard_layout.parse_layout
      "resources/standard_keyboard_layout.json" in
  let rows = Keyboard_layout.get_rows keyboard_layout in
  let cols = Keyboard_layout.get_cols keyboard_layout in
  let keyboard = Keyboard.create_keyboard (rows, cols) in
  {
    window_w = 1280;
    window_h = 720;
    keyboard = keyboard;
    keyboard_layout = keyboard_layout;
    song = eq_song;
    state = SKeyboard;
    midi_filename = "resources/eq_data/eq_midi_0.json";
    should_load_midi = true;
    is_playing = false;
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

let midi_is_playing () = model.is_playing

let midi_should_load () = model.should_load_midi
