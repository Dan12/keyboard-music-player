type state = SKeyboard | SFileChooser

let current_state = ref SKeyboard

let set_state s =
  current_state := s

let get_state s =
  !current_state

