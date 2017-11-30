open Sys
open Keyboard

type filename_button = string

type file_button =
  | Cancel
  | Select

type filename_buttons = (filename_button * Keyboard.key_state) array

type file_buttons = file_button array

let num_file_buttons = 2

let get_file_button i =
  if i = 0 then Cancel
  else Select

let clear buttons =
  for i = 0 to num_file_buttons-1 do
    buttons.(i) <- (get_file_button i)
  done

let create_file_buttons () =
  let buttons = Array.make num_file_buttons (Cancel) in
  clear buttons;
  buttons

let clear_filename size jsons buttons =
  for i = 0 to size-1 do
    buttons.(i) <- (List.nth jsons i, KSUp)
  done

let contains s1 s2 =
  let size = String.length s1 in
  let contain = ref false in
  let i = ref 0 in
  while !i < (String.length s2 - size + 1) && !contain = false do
    if String.sub s2 !i size = s1 then contain := true
    else i := !i + 1
  done;
  !contain

let create_empty_filename_list () =
  Array.make 0 ("",KSUp)

let create_filename_buttons f =
  let filename_list = if Sys.is_directory (f) then
    Sys.readdir f |> Array.to_list
    else [] in
  if (List.length filename_list) > 0 then
    let json_list = List.fold_left
      (fun j s -> if contains ".json" s && contains "midi" s
        then s::j else j) [] filename_list in
    let size = List.length json_list in
    if size > 0 then
      let filename_buttons = Array.make size (((List.hd json_list):filename_button), KSUp) in
      clear_filename size json_list filename_buttons;
      filename_buttons
    else Array.make 0 ("",KSUp)
  else Array.make 0 ("",KSUp)

let press_filename_button file buttons =
  for i = 0 to Array.length(buttons)-1 do
    let (button, state) = Array.get buttons i in
    if button = file then
      buttons.(i) <- (button, KSDown)
    else buttons.(i) <- (button, KSUp)
  done

let selected_filename buttons =
  let selected = ref None in
  for i = 0 to Array.length(buttons)-1 do
    let (button, state) = Array.get buttons i in
    if state = KSDown then
      selected := Some button
  done;
  !selected
