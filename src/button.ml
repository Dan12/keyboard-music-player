open Keyboard

type button =
  | Load
  | Play
  | Pause
  | Stop

type buttons = (button * Keyboard.key_state) array

let get_button i =
  if i = 0
  then Load
  else if i = 1
  then Play
  else if i = 2
  then Pause
  else Stop

let get_index = function
  | Load -> 0
  | Play -> 1
  | Pause -> 2
  | Stop -> 3

let num_buttons = 4

let clear buttons =
  for i = 0 to num_buttons-1 do
    buttons.(i) <- (get_button i, KSUp)
  done

let press_button button buttons =
  clear buttons;
  buttons.(get_index button) <- (button, KSDown)

let create_buttons () =
  let buttons = Array.make num_buttons (Load, KSUp) in
  clear buttons;
  press_button Stop buttons;
  buttons
