open Tsdl.Sdl.Event
open Button
open Model
open File_button

let input_event_singleton = ref None
let recent_click = ref (Unix.gettimeofday())

let handle_keyboard_output output =
  let keyboard = Model.get_keyboard () in
  (* pass it to the keyboard and check if it modifies state *)
  if Keyboard.process_event output keyboard then
    (* if it does, pass it to the sound manager *)
    begin
      match output with
      | Keyboard_layout.KOKeydown (r,c) ->
        Sound_manager.key_pressed (r,c)
      | Keyboard_layout.KOKeyup (r,c) ->
        Sound_manager.key_released (r,c)
      | _ -> ()
    end
  else
    (match output with
     | Keyboard_layout.KOSoundpackSet i ->
       let song = Model.get_song () in
       Song.set_sound_pack i song
     | Keyboard_layout.KOSpace ->
       if Model.midi_is_playing() then Model.pause_midi()
       else Model.start_midi()
     | _ -> ())

let handle_keyboard input_event =
  match Model.get_state () with
  | Model.SKeyboard ->
    let layout = Model.get_keyboard_layout () in
    (* get the mapped output *)
    let output = Keyboard_layout.process_key input_event layout in
    handle_keyboard_output output
  | _ -> ()

let clear_keyboard () =
  let layout = Model.get_keyboard_layout() in
  let keyboard = Model.get_keyboard() in
  let rows = Keyboard_layout.get_rows layout in
  let cols = Keyboard_layout.get_cols layout in
  for row = 0 to rows - 1 do
    for col = 0 to cols - 1 do
      Keyboard.process_event (Keyboard_layout.KOKeyup (row, col)) keyboard |> ignore
    done;
  done

let contains s1 s2 =
  let size = String.length s1 in
  let contain = ref false in
  let i = ref 0 in
  while !i < (String.length s2 - size + 1) && !contain = false do
    if String.sub s2 !i size = s1 then
      contain := true
    else
      i := !i + 1
  done;
  !contain

let handle_mouse_up x y t =
  match Model.get_state () with
  | SKeyboard ->
    begin
      match Gui.button_pressed (x, y) with
      | Some button ->
        (match button with
        | Load -> Model.set_state Model.SFileChooser
        | Play -> Model.start_midi()
        | Pause -> Model.pause_midi()
        | Stop -> Model.stop_midi();
          clear_keyboard())
      | None -> ()
    end
  | SFileChooser ->
    begin
      match Gui.file_button_pressed (x, y) with
      | Some button ->
        begin
          match button with
            | Cancel ->
              Model.set_filename_buttons (Model.get_file_location());
              Model.set_state Model.SKeyboard
            | Select ->
              begin
                match File_button.selected_filename (Model.get_filename_buttons()) with
                | Some button ->
                  let index = String.index button '_' in
                  let folder = String.sub button 0 index in
                  if contains "midi" button then
                    Model.set_midi_filename ((Model.get_file_location())^folder^"_data/"^button)
                  else
                    Model.set_song (Song.parse_song_file ((Model.get_file_location())^folder^"_data/"^button))
                | None -> ()
              end;
              Model.set_filename_buttons (Model.get_file_location());
            Model.set_state Model.SKeyboard
          end;
      | None -> ()
    end;

    match Gui.filename_button_pressed (x, y) with
    | Some button ->
      if (t -. !recent_click) < 0.3 then
        let index = String.index button '_' in
        let folder = String.sub button 0 index in
        if contains "midi" button then
          Model.set_midi_filename ((Model.get_file_location())^folder^"_data/"^button)
        else
          Model.set_song (Song.parse_song_file ((Model.get_file_location())^folder^"_data/"^button));
        Model.set_filename_buttons (Model.get_file_location());
        Model.set_state Model.SKeyboard
      else
        File_button.press_filename_button button (Model.get_filename_buttons())
    | None -> ()

let event_callback event =
  match enum (get event typ) with
  | `Key_down ->
    let keycode = get event keyboard_keycode in
    (* print_endline (string_of_int keycode); *)
    handle_keyboard (Keyboard_layout.KIKeydown keycode)
  | `Key_up ->
    let keycode = get event keyboard_keycode in
    (* print_endline (string_of_int keycode); *)
    handle_keyboard (Keyboard_layout.KIKeyup keycode)
  | `Mouse_button_down ->
    (* let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in *)
    ()
  | `Mouse_button_up ->
    let click = Unix.gettimeofday() in
    let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in
    handle_mouse_up mouse_x mouse_y click;
    recent_click := click
  | `Mouse_motion ->
    (*let mouse_x = get event mouse_button_x in
    let mouse_y = get event mouse_button_y in *)
    ()
  | `Mouse_wheel ->
    (* let scroll_dx = get event mouse_wheel_x in
    let scroll_dy = get event mouse_wheel_y in *)
    ()
  | _ -> ()
