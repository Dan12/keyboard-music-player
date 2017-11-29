type file_button =
  | Cancel
  | Select

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
