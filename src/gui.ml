(* TODO needs comments for all functions and variables except draw *)

open Tsdl
open Keyboard_layout
open Keyboard
open Model

let scrub:(Sdl.rect option ref) = ref None

let bpm:(Sdl.rect option ref) = ref None

let keyboard_padding_w = 20
let keyboard_padding_h = 30
let percent_key_padding = 10

let arrow_width_height_ratio = 2

let num_graphic_bars = 48
let graphic_padding_w = 25
let graphic_padding_h = 20
let percent_graphic_padding = 16
let max_amplitude = 60
let max_frequency = 63 (* >= num_graphic_bars/2 - 1*)

let black = Sdl.Color.create 0 0 0 255
let red = Sdl.Color.create 204 24 30 255

let background_color = Sdl.Color.create 255 255 255 255
let keyboard_text_color = Sdl.Color.create 0 0 0 255
let keyboard_border_color = Sdl.Color.create 0 0 0 255

let keyboard_pressed_color = Sdl.Color.create 128 128 255 255
let key_background = Sdl.Color.create 255 255 255 192

let min_graphic_color = Sdl.Color.create 0 255 0 255
let max_graphic_color = Sdl.Color.create 255 0 0 255



(*
 * Assumes the key list has length of [row] * [col]
 *)
let draw_keyboard renderer keyboard_layout keyboard x y w rows cols =
  let offset = w / cols in
  let key_size = (100 - percent_key_padding) * offset / 100 in
  let font_size = 7 * key_size / 10 in
  for r = 0 to rows - 1 do
    for c = 0 to cols - 1 do
      let key_visual = Keyboard_layout.get_visual (r, c) keyboard_layout in
      let key_state = Keyboard.get_state (r, c) keyboard in
      let curr_x = c * offset + x in
      let curr_y = r * offset + y in
      Gui_utils.draw_key renderer curr_x curr_y key_size key_size keyboard_pressed_color key_background keyboard_border_color key_state;
      Gui_utils.draw_key_text renderer curr_x curr_y key_size key_size font_size keyboard_text_color key_visual
    done;
  done;
  offset * rows

  (*
   * Assumes the key list has length of [row] * [col]
   *)
let draw_arrows r keyboard x y w =
  let x_offset = w / 3 in
  let y_offset = x_offset / arrow_width_height_ratio in
  let w_key = (100 - percent_key_padding) * x_offset / 100 in
  let h_key = (100 - percent_key_padding) * y_offset / 100 in

  let left_state = if Model.get_song () |> Song.get_sound_pack = 0 then KSDown else KSUp in
  let up_state = if Model.get_song () |> Song.get_sound_pack = 1 then KSDown else KSUp in
  let down_state = if Model.get_song () |> Song.get_sound_pack = 2 then KSDown else KSUp in
  let right_state = if Model.get_song () |> Song.get_sound_pack = 3 then KSDown else KSUp in

  (* draw left *)
  Gui_utils.draw_key r x (y + y_offset) w_key h_key keyboard_pressed_color key_background keyboard_border_color left_state;
  Gui_utils.draw_left r x (y + y_offset) w_key h_key;

  (* draw down *)
  Gui_utils.draw_key r (x + x_offset) (y + y_offset) w_key h_key keyboard_pressed_color key_background keyboard_border_color down_state;
  Gui_utils.draw_down r (x + x_offset) (y + y_offset) w_key h_key;

  (* draw up *)
  Gui_utils.draw_key r (x + x_offset) y w_key h_key keyboard_pressed_color key_background keyboard_border_color up_state;
  Gui_utils.draw_up r (x + x_offset) y w_key h_key;

  (* draw right *)
  Gui_utils.draw_key r (x + 2 * x_offset) (y + y_offset) w_key h_key keyboard_pressed_color key_background keyboard_border_color right_state;
  Gui_utils.draw_right r (x + 2 * x_offset) (y + y_offset) w_key h_key;
  2 * y_offset

let draw_buttons r x y w =
  let buttons = Model.get_midi_buttons() in
  let offset = w / (List.length buttons) in
  let size = (100 - percent_key_padding) * offset / 100 in
  let iter = fun i b ->
    let button_x = i * offset + x in
    Button_standard.set_area b button_x y size size;
    Button_standard.draw b r in
  List.iteri iter buttons;
  size

let draw_play_button r x y w =
  let b = Model.get_play_button() in
  let h = w / 5 in
  Button_standard.set_area b x y w h;
  Button_standard.draw b r;
  h

let draw_synth_button r x y w =
  let b = Model.get_synth_button() in
  let h = w / 5 in
  Button_standard.set_area b x y w h;
  Button_standard.draw b r;
  h

let draw_filter_buttons r x y w h =
  let buttons = Model.get_filter_buttons() in
  let offset = h / (List.length buttons) in
  let button_h = (100 - percent_key_padding) * offset / 100 in
  let iter i b =
    let button_y = y + i * offset in
    Button_standard.set_area b x button_y w button_h;
    Button_standard.draw b r in
  List.iteri iter buttons

let draw_grid r x y w =
  let b = Model.get_synth_grid() in
  let h = w in
  Button_standard.set_area b x y w h;
  Button_standard.draw b r;
  h

let draw_bpm r y =
  let size = 20 in
  let x = ((Model.get_bpm_pos()|> int_of_float) - size/2) in

  (* Rectangle for the slider itself. *)
  let rect = Sdl.Rect.create (x+(size/4)) y (size/2) size in
  bpm := Some rect;

  (* Line for the bpm slider. *)
  let line_h = 3 in
  let line = Sdl.Rect.create (Model.get_bpm_pos_min()|> int_of_float)
      (y + (size / 2) - 1) ((Model.get_bpm_pos_max()|> int_of_float)-
                            (Model.get_bpm_pos_min()|> int_of_float)) line_h in
  Gui_utils.set_color r black;
  let _ = Sdl.render_fill_rect r (Some line) in

  (* Vertical red line that is default bpm for song. *)
  let song_bpm = Model.get_song() |> Song.get_bpm in
  let bpm_diff = Metronome.get_max_bpm() -. Metronome.get_min_bpm() in
  let percent = ((float_of_int song_bpm)-.Metronome.get_min_bpm())/. bpm_diff in
  let bpm_pos = int_of_float
      ((percent *. (Model.get_bpm_pos_max() -. Model.get_bpm_pos_min())) +.
       Model.get_bpm_pos_min()) in
  let def_line = Sdl.Rect.create (bpm_pos-1) (y - (size / 2)) (2) (size*2) in
  Gui_utils.set_color r red;
  let _ = Sdl.render_fill_rect r (Some def_line) in

  (* Draws the slider. *)
  Gui_utils.set_color r black;
  let _ = Sdl.render_fill_rect r (Some rect) in

  (* Text for current bpm. *)
  let text = "BPM: "^(string_of_int(Metronome.get_bpm()))  in
  Gui_utils.draw_text r (int_of_float (Model.get_bpm_pos_max()) + (size*3))
    (y + (size / 2) - 1) size black text;
  ()

let draw_scrub r y =
  let size = 30 in
  let scrub_pos = Model.get_scrub_pos() |> int_of_float in
  let x = scrub_pos - size/2 in
  let rect = Sdl.Rect.create x y size size in
  scrub := Some rect;

  let scrub_start_x = Model.get_scrub_pos_min() |> int_of_float in
  let scrub_end_x = Model.get_scrub_pos_max() |> int_of_float in
  let line_y = y + size / 2 - 1 in
  let line_h = 3 in
  Gui_utils.set_color r red;
  let played_line = Sdl.Rect.create scrub_start_x line_y
      (scrub_pos - scrub_start_x) line_h in
  let _ = Sdl.render_fill_rect r (Some played_line) in
  Gui_utils.set_color r black;
  let remaining_line = Sdl.Rect.create scrub_pos line_y
      (scrub_end_x - scrub_pos) line_h in
  let _ = Sdl.render_fill_rect r (Some remaining_line) in

  let current_beat = Metronome.get_beat() |> int_of_float |> string_of_int in
  let total_beats = Model.get_beats() |> int_of_float |> string_of_int in
  let text = current_beat ^ "/" ^ total_beats in
  Gui_utils.draw_text r (scrub_end_x + size*2) line_y size black text;

  (* draw the scrub from ealier last. *)
  Gui_utils.set_color r black;
  let _ = Sdl.render_fill_rect r (Some rect) in
  ()

let clear r =
  Gui_utils.set_color r background_color;
  let _ = Sdl.render_clear r in
  ()

(* flush the buffer *)
let present r =
  let _ = Sdl.render_present r in
  ()

let get_amplitude_color_element min max amp =
  min + amp * ((max - min) / max_amplitude)

let get_amplitude_color amp =
  let min_r = Sdl.Color.r min_graphic_color in
  let min_g = Sdl.Color.g min_graphic_color in
  let min_b = Sdl.Color.b min_graphic_color in

  let max_r = Sdl.Color.r max_graphic_color in
  let max_g = Sdl.Color.g max_graphic_color in
  let max_b = Sdl.Color.b max_graphic_color in

  let r = get_amplitude_color_element min_r max_r amp in
  let g = get_amplitude_color_element min_g max_g amp in
  let b = get_amplitude_color_element min_b max_b amp in
  Sdl.Color.create r g b 255

let draw_graphic_segment r amp x y w h =
  let segment_color = get_amplitude_color amp in
  Gui_utils.set_color r segment_color;
  let rect = Sdl.Rect.create x y w h in
  let _ = Sdl.render_fill_rect r (Some rect) in
  ()

let rec is_zero arr i =
  if i >= Array.length arr
  then true
  else arr.(i) = 0 && (is_zero arr (i + 1))

let draw_graphics r amplitudes x y w h =
  let should_noise = is_zero amplitudes 0 in
  let num_bars = Array.length amplitudes in
  let offset = (w + num_bars / 2) / num_bars in
  let bar_w = (100 - percent_graphic_padding) * offset / 100 in
  let segment_h = (h + max_amplitude / 2) / max_amplitude in
  for height = 0 to max_amplitude do
    for bar = 0 to num_bars - 1 do
      let segment_x = x + bar * offset in
      let segment_y = (y + h) - (height + 1) * segment_h in
      if height <= amplitudes.(bar) || (should_noise && height = 1 && Random.int 2 = 1)
      then draw_graphic_segment r height segment_x segment_y bar_w segment_h
      else ()
    done;
  done

let rec sum_array arr from_i to_i =
  if from_i >= to_i
  then 0
  else arr.(from_i) + (sum_array arr (from_i + 1) to_i)

let get_amplitudes size =
  let complex_arr = Model.get_buffer () in

  let normalize = fun compl ->
    int_of_float (2.0 *. (Complex.norm compl))
  in

  let normalized = Array.map normalize complex_arr in
  let normalized_len = min (max_frequency + 1) (Array.length normalized) in (* truncate unwanted frequencies *)

  let condensed_len = size / 2 in
  let condense i =
    let ratio = normalized_len / condensed_len in
    let from_i = i * ratio in
    let to_i = (i + 1) * ratio in
    (sum_array normalized from_i to_i) / ratio
  in
  let condensed = Array.init condensed_len condense in

  let init_i i = (* meet base in the middle *)
    condensed.(abs(condensed_len - 1 + i / condensed_len - i))
  in
  (* let init_i i = (* put base on the ends *)
    if (i >= condensed_len)
    then condensed.(size - 1 - i)
    else condensed.(i)
  in *)
  Array.init size init_i

let draw_keyboard_visual r =
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  let keyboard = Model.get_keyboard () in
  let keyboard_layout = Model.get_keyboard_layout () in

  let amplitudes = get_amplitudes num_graphic_bars in
  let num_bars = Array.length amplitudes + 1 in
  let graphics_x = graphic_padding_w in
  let graphics_y = graphic_padding_h in
  let graphics_w = (window_w - 2 * graphic_padding_w) * 100 * num_bars /
                   (100 * num_bars - percent_graphic_padding) in
  let graphics_h = window_h - 2 * graphic_padding_h in
  draw_graphics r amplitudes graphics_x graphics_y graphics_w graphics_h;

  let keyboard_x = keyboard_padding_w in
  let keyboard_y = keyboard_padding_h in
  let keyboard_rows = Keyboard_layout.get_rows keyboard_layout in
  let keyboard_cols = Keyboard_layout.get_cols keyboard_layout in
  let keyboard_w = (window_w - 2 * keyboard_padding_w) * 100 * keyboard_cols /
                   (100 * keyboard_cols - percent_key_padding) in
  let keyboard_h = draw_keyboard r keyboard_layout keyboard
      keyboard_x keyboard_y keyboard_w keyboard_rows keyboard_cols in
  (keyboard_x, keyboard_y, keyboard_w, keyboard_h)

let draw_file_buttons r x y w =
  let offset = w / 2 in
  let size = (100 - percent_key_padding) * offset / 100 in
  let iter i b =
    let button_x = i * offset + x in
    Button_standard.set_area b button_x y size size;
    Button_standard.draw b r in
  List.iteri iter (Model.get_file_buttons());
  size

let draw_filename_buttons r x y w =
  let buttons = Model.get_filename_buttons() in

  let x_offset = 2 * w / 3 in
  let y_offset = w / 8 in

  let button_w = (100 - percent_key_padding) * x_offset / 100 in
  let button_h = (100 - percent_key_padding) * y_offset / 100 in

  let iter i b =
    let button_x = x + (i / 8) * x_offset in
    let button_y = y + (i mod 8) * y_offset in

    Button_standard.set_area b button_x button_y button_w button_h;
    Button_standard.draw b r
  in
  List.iteri iter buttons;
  button_h

let draw_song_player r =
  let keyboard = Model.get_keyboard () in
  let keyboard_coords = draw_keyboard_visual r in
  let keyboard_x, keyboard_y, keyboard_w, keyboard_h = keyboard_coords in

  let arrows_w = keyboard_w / 6 in
  let arrows_x = keyboard_x + keyboard_w - arrows_w - 5 in
  let arrows_y = 21 * keyboard_h / 20 + keyboard_y in
  let arrows_h = draw_arrows r keyboard arrows_x arrows_y arrows_w in


  let buttons_w = arrows_w * 2 in
  let buttons_x = keyboard_x in
  let buttons_y = arrows_y in
  let buttons_h = draw_buttons r buttons_x buttons_y buttons_w in


  let synth_button_x = arrows_x in
  let synth_button_y = arrows_y + 5 * arrows_h / 4 in
  let synth_button_w = arrows_w -  arrows_w / 21 in
  let _ = draw_synth_button r synth_button_x synth_button_y synth_button_w in

  let bpm_y = arrows_y + arrows_h + 3 * keyboard_padding_h / 2 in
  let _ = draw_bpm r bpm_y in

  let scrub_y = buttons_y + buttons_h + 2 * keyboard_padding_h in
  let _ = draw_scrub r scrub_y in
  ()

let draw_filechooser r =
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  let filename_buttons_x = window_w / 25 in
  let filename_buttons_y = window_h / 15 in
  let filename_buttons_w = window_h * 3 / 4 in
  let _ = draw_filename_buttons r filename_buttons_x filename_buttons_y filename_buttons_w in

  let buttons_x = window_w - window_w / 5 in
  let buttons_y = window_h - window_h / 6 in
  let buttons_w = window_w / 5 in
  let _ = draw_file_buttons r buttons_x buttons_y buttons_w in
  ()

let draw_synthesizer r =
  let keyboard_coords = draw_keyboard_visual r in
  let keyboard_x, keyboard_y, keyboard_w, keyboard_h = keyboard_coords in

  let grid_x = keyboard_x in
  let grid_y = 21 * keyboard_h / 20 + keyboard_y in
  let grid_w = keyboard_w / 6 - 10 in
  let grid_h = draw_grid r grid_x grid_y grid_w in

  let filters_x = grid_x + 5 * grid_w / 4 in
  let filters_y = grid_y + 5 in
  let filters_w = 3 * grid_w / 4 in
  let filters_h = grid_h in
  draw_filter_buttons r filters_x filters_y filters_w filters_h;

  let synth_button_w = grid_w in
  let synth_button_x = keyboard_x + keyboard_w - synth_button_w - 15 in
  let synth_button_y = grid_y in
  let _ = draw_play_button r synth_button_x synth_button_y synth_button_w in
  ()


let draw r =
  clear r;
  begin
    match Model.get_state () with
    | SKeyboard -> draw_song_player r
    | SFileChooser -> draw_filechooser r
    | SSynthesizer -> draw_synthesizer r
  end;
    present r

(*is [s] is "scrub" then for midi slider, if "bpm" then for bpm slider*)
let scrub_pressed (x,y) s =
  let matched = if s = "scrub" then
      !scrub else !bpm in
  match matched with
  | None -> false
  | Some rect ->
    let rect_x = Sdl.Rect.x rect in
    let rect_y = Sdl.Rect.y rect in
    let rect_w = Sdl.Rect.w rect in
    let rect_h = Sdl.Rect.h rect in
    rect_x <= x && x <= (rect_x+rect_w) && rect_y <= y && y <= (rect_y+rect_h)
