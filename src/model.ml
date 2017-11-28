open Keyboard
open Keyboard_layout
open Song

type model = {
  mutable keyboard: keyboard;
  mutable keyboard_layout: keyboard_layout;
  mutable song: song;
  
}
