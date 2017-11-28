open Keyboard
open Keyboard_layout
open Song

type state = SKeyboard | SFileChooser

type model = {
  mutable keyboard: keyboard;
  mutable keyboard_layout: keyboard_layout;
  mutable song: song;
  mutable state: state
}

let model:model =
let eq_song = Song.parse_song_file "resources/eq_data/eq.json" in
let keyboard_layout = Keyboard_layout.parse_layout "resources/standard_keyboard_layout.json" in
let rows = Keyboard_layout.get_rows keyboard_layout in
let cols = Keyboard_layout.get_cols keyboard_layout in
let keyboard = Keyboard.create_keyboard (rows, cols) in
{
  keyboard = keyboard;
  keyboard_layout = keyboard_layout;
  song = eq_song;
  state = SKeyboard
}

let set_keyboard k =
  model.keyboard <- k

let get_keyboard =
  model.keyboard

let set_keyboard_layout kl =
  model.keyboard_layout <- kl

let get_keyboard_layout =
  model.keyboard_layout

let set_song s =
  model.song <- s

let get_song =
  model.song

let set_state s =
  model.state <- s

let get_state s =
  model.state
