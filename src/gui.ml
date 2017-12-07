(* TODO needs comments for all functions and variables except draw *)

open Tsdl
open Keyboard_layout
open Keyboard
open Model

type slider = Sdl.rect option ref

let scrub:slider = ref None
let bpm:slider = ref None
let a_slider:slider = ref None
let d_slider:slider = ref None
let s_slider:slider = ref None
let r_slider:slider = ref None

(* amount of padded from the edge of the window to the keyboard *)
let keyboard_padding_w = 20
let keyboard_padding_h = 30

(* percentage of space we put between keys based on keysize *)
let percent_key_padding = 10

(* for the soundpack arrows, the width is 2* the height *)
let arrow_width_height_ratio = 2

(* number of bars in the sound visualizer *)
let num_graphic_bars = 48

(* amount of padded from the edge of the window to the visual bounds *)
let graphic_padding_w = 25
let graphic_padding_h = 20

(* percentage of space we put between columns based on width *)
let percent_graphic_padding = 16

(* capped amplitude for the graphic visualizer *)
let max_amplitude = 60
(* we only look at the lower [max_frequency] frequencies to visualize *)
let max_frequency = 63 (* >= num_graphic_bars/2 - 1*)

(* here we define standard colors that we use throughout the gui *)
let white = Sdl.Color.create 255 255 255 255
let black = Sdl.Color.create 0 0 0 255
let red = Sdl.Color.create 204 24 30 255

let background_color = white
let keyboard_text_color = black
let keyboard_border_color = black

let keyboard_pressed_color = Sdl.Color.create 128 128 255 255
let key_background = Sdl.Color.create 255 255 255 192

let min_graphic_color = Sdl.Color.create 0 255 0 255
let max_graphic_color = Sdl.Color.create 255 0 0 255



(*
 * Draws a keyboard to the gui starting a (x, y) with a width of w. The height
 * is calculated based on the width.
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
 * Draws the sound pack manager. There are a maximum of four sound packs.
 * Therefore, we use all arrow keys. The dimensions are the same as in
 * [draw_keyboard].
 *)
let draw_arrows r x y w =
  let x_offset = w / 3 in
  let y_offset = x_offset / arrow_width_height_ratio in
  let w_key = (100 - percent_key_padding) * x_offset / 100 in
  let h_key = (100 - percent_key_padding) * y_offset / 100 in

  let sound_pack = Model.get_song () |> Song.get_sound_pack in
  let get_state i = if sound_pack = i then KSDown else KSUp in
  let left_state = get_state 0 in
  let up_state = get_state 1 in
  let down_state = get_state 2 in
  let right_state = get_state 3 in

  (* draw left *)
  let left_y = y + y_offset in
  Gui_utils.draw_key r x left_y w_key h_key keyboard_pressed_color key_background keyboard_border_color left_state;
  Gui_utils.draw_left r x left_y w_key h_key;

  (* draw down *)
  let down_x = x + x_offset in
  let down_y = left_y in
  Gui_utils.draw_key r down_x down_y w_key h_key keyboard_pressed_color key_background keyboard_border_color down_state;
  Gui_utils.draw_down r down_x down_y w_key h_key;

  (* draw up *)
  let up_x = down_x in
  Gui_utils.draw_key r up_x y w_key h_key keyboard_pressed_color key_background keyboard_border_color up_state;
  Gui_utils.draw_up r up_x y w_key h_key;

  (* draw right *)
  let right_x = x + 2 * x_offset in
  let right_y = down_y in
  Gui_utils.draw_key r right_x right_y w_key h_key keyboard_pressed_color key_background keyboard_border_color right_state;
  Gui_utils.draw_right r right_x right_y w_key h_key;
  2 * y_offset

(* draw a button with the given bounds [x], [y], [w], and [h] *)
let draw_button b r x y w h =
  Button.set_area b x y w h;
  Button.draw b r

(* Draw buttons evenly spaced horizontally to cover the given bounds *)
let draw_horizontal_buttons bs r x y w h =
  let offset = w / (List.length bs) in
  let width = (100 - percent_key_padding) * offset / 100 in
  let iter i b = draw_button b r (i * offset + x) y width h in
  List.iteri iter bs

(* Draw buttons evenly spaced vertically to cover the given bounds *)
let draw_vertical_buttons bs r x y w h =
  let offset = h / (List.length bs) in
  let height = (100 - percent_key_padding) * offset / 100 in
  let iter i b = draw_button b r x (i * offset + y) w height in
  List.iteri iter bs

(*
 * draw the BPM slider at the given y value. the x value has been defined
 * externally in the model.
 *)
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

(*
 * Draw the song position scrubber to the gui at the given [y] value. The other
 * bounds are defined externally in the model.
 *)
let draw_scrub r y =
  (* draw square scrub *)
  let size = 30 in
  let scrub_pos = Model.get_scrub_pos() |> int_of_float in
  let x = scrub_pos - size/2 in
  let rect = Sdl.Rect.create x y size size in
  scrub := Some rect;

  (* draw red & black time lines across the screen *)
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

  (* text for current beats & total number of beats *)
  let current_beat = Metronome.get_beat() |> int_of_float |> string_of_int in
  let total_beats = Model.get_beats() |> int_of_float |> string_of_int in
  let text = current_beat ^ "/" ^ total_beats in
  Gui_utils.draw_text r (scrub_end_x + size*2) line_y size black text;

  (* draw the scrub from ealier last. *)
  Gui_utils.set_color r black;
  let _ = Sdl.render_fill_rect r (Some rect) in
  ()

(* clear the gui's view to have just the background *)
let clear r =
  Gui_utils.set_color r background_color;
  let _ = Sdl.render_clear r in
  ()

(*
 * flush the gui buffer to the screen. This updates the gui and should be
 * called 60 times a second.
 *)
let present r =
  let _ = Sdl.render_present r in
  ()

(*
 * given the ratio between [amp] and [max_amplitude] return the value with the
 * same ratio to [max - min]
 *)
let get_amplitude_color_element min max amp =
  min + amp * ((max - min) / max_amplitude)

(*
 * get the color that corresponds to the given [amp] based on
 * [min_graphic_color] and [max_graphic_color] and the ratio between [amp]
 * and [max_amplitude].
 *)
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

(*
 * draw a segment of the sound visualizer with the requested bounds at the
 * given amplitude.
 *)
let draw_graphic_segment r amp x y w h =
  let segment_color = get_amplitude_color amp in
  Gui_utils.set_color r segment_color;
  let rect = Sdl.Rect.create x y w h in
  let _ = Sdl.render_fill_rect r (Some rect) in
  ()

(* return true if the array has only 0's in the given range, false otherwise. *)
let rec is_zero arr i =
  if i >= Array.length arr
  then true
  else arr.(i) = 0 && (is_zero arr (i + 1))

(*
 * draw a visualization of each frequencies amplitude. Uses the given bounds.
 * amplidudes grow up and attempt to fill the entire bouding box.
 *)
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

(* return the sum of each element in an array within the given bounds *)
let rec sum_array arr from_i to_i =
  if from_i >= to_i then 0
  else arr.(from_i) + (sum_array arr (from_i + 1) to_i)

(*
 * return an array of amplitudes of raising frequencies, the number of elements
 * is given by [size]. If size is too small, the array will be condensed by
 * averaging the elements that fit into each index. [size] must be less than or
 * equal to the total number of available frequencies.
 *)
let get_amplitudes size =
  let complex_arr = Model.get_buffer () in

  let normalize compl = int_of_float (2.0 *. (Complex.norm compl)) in
  let normalized = Array.map normalize complex_arr in

  (* truncate unwanted frequencies *)
  let normalized_len = min (max_frequency + 1) (Array.length normalized) in

  let condensed_len = size / 2 in
  (* create index i of the condensed array but averaging the index range
   * this element contains *)
  let condense i =
    let ratio = normalized_len / condensed_len in
    let from_i = i * ratio in
    let to_i = (i + 1) * ratio in
    (sum_array normalized from_i to_i) / ratio in
  let condensed = Array.init condensed_len condense in

  let init_i i = (* meet base in the middle *)
    condensed.(abs(condensed_len - 1 + i / condensed_len - i)) in
  Array.init size init_i

(*
 * draw the keyboard and the graphical visualization of the current sounds
 * playing.
 *)
let draw_keyboard_visual r =
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  let keyboard = Model.get_keyboard () in
  let keyboard_layout = Model.get_keyboard_layout () in

  (* draw graphics *)
  let amplitudes = get_amplitudes num_graphic_bars in
  let num_bars = Array.length amplitudes + 1 in
  let graphics_x = graphic_padding_w in
  let graphics_y = graphic_padding_h in
  let graphics_w = (window_w - 2 * graphic_padding_w) * 100 * num_bars /
                   (100 * num_bars - percent_graphic_padding) in
  let graphics_h = window_h - 2 * graphic_padding_h in
  draw_graphics r amplitudes graphics_x graphics_y graphics_w graphics_h;

  (* draw keyboard *)
  let keyboard_x = keyboard_padding_w in
  let keyboard_y = keyboard_padding_h in
  let keyboard_rows = Keyboard_layout.get_rows keyboard_layout in
  let keyboard_cols = Keyboard_layout.get_cols keyboard_layout in
  let keyboard_w = (window_w - 2 * keyboard_padding_w) * 100 * keyboard_cols /
                   (100 * keyboard_cols - percent_key_padding) in
  let keyboard_h = draw_keyboard r keyboard_layout keyboard
      keyboard_x keyboard_y keyboard_w keyboard_rows keyboard_cols in
  (keyboard_x, keyboard_y, keyboard_w, keyboard_h)

(* draw the buttons that correspond to possible files the user may load. *)
let draw_filename_buttons r x y w =
  let buttons = Model.get_filename_buttons() in

  let x_offset = 2 * w / 3 in
  let y_offset = w / 8 in

  let button_w = (100 - percent_key_padding) * x_offset / 100 in
  let button_h = (100 - percent_key_padding) * y_offset / 100 in

  let draw_button i b =
    let button_x = x + (i / 8) * x_offset in
    let button_y = y + (i mod 8) * y_offset in

    Button.set_area b button_x button_y button_w button_h;
    Button.draw b r in
  List.iteri draw_button buttons;
  button_h

(* draw the adsr (Attack Decay Sustain Release) sliders for the sythesizer. *)
let draw_adsr_sliders r' y gap =
  let size_x = 10 in
  let size_y = 20 in

  let start = Model.get_adsr_pos_min() |> int_of_float in
  let line_length = Model.get_adsr_pos_max() -. Model.get_adsr_pos_min() in
  let line_h = 3 in
  let line1 = Sdl.Rect.create start y (line_length |> int_of_float) line_h in
  let line2 = Sdl.Rect.create start (y + gap) (line_length |> int_of_float)
      line_h in
  let line3 = Sdl.Rect.create start (y + 2*gap) (line_length |> int_of_float)
      line_h in
  let line4 = Sdl.Rect.create start (y+3*gap) (line_length |> int_of_float)
      line_h in
  let _ = Sdl.render_fill_rect r' (Some line1) in
  let _ = Sdl.render_fill_rect r' (Some line2) in
  let _ = Sdl.render_fill_rect r' (Some line3) in
  let _ = Sdl.render_fill_rect r' (Some line4) in

  Gui_utils.draw_text r' (start-15) y 20 black "A";
  Gui_utils.draw_text r' (start-15) (y+gap) 20 black "D";
  Gui_utils.draw_text r' (start-15) (y+2*gap) 20 black "S";
  Gui_utils.draw_text r' (start-15) (y+3*gap) 20 black "R";

  let (a,d,s,r) = Model.get_adsr_params() in
  let a_pos = int_of_float (a *. line_length) in
  let d_pos = int_of_float (d *. line_length) in
  let s_pos = int_of_float (s *. line_length) in
  let r_pos = int_of_float (r *. line_length) in
  let rect1 = Sdl.Rect.create (start + a_pos) (y - size_y/2) size_x size_y in
  let rect2 = Sdl.Rect.create (start + d_pos) (y + gap - size_y/2) size_x
      size_y in
  let rect3 = Sdl.Rect.create (start + s_pos) (y + 2*gap - size_y/2)
      size_x size_y in
  let rect4 = Sdl.Rect.create (start + r_pos) (y + 3*gap - size_y/2)
      size_x size_y in
  a_slider := Some rect1;
  d_slider := Some rect2;
  s_slider := Some rect3;
  r_slider := Some rect4;
  let _ = Sdl.render_fill_rect r' (Some rect1) in
  let _ = Sdl.render_fill_rect r' (Some rect2) in
  let _ = Sdl.render_fill_rect r' (Some rect3) in
  let _ = Sdl.render_fill_rect r' (Some rect4) in

  let tail = Model.get_adsr_pos_max() |> int_of_float in
  let float_to_string = Printf.sprintf "%.4f" in
  Gui_utils.draw_text r' (tail+45) y 20 black (float_to_string a);
  Gui_utils.draw_text r' (tail+45) (y+gap) 20 black (float_to_string d);
  Gui_utils.draw_text r' (tail+45) (y+2*gap) 20 black (float_to_string s);
  Gui_utils.draw_text r' (tail+45) (y+3*gap) 20 black (float_to_string r);
  ()

(* draw the main window layout, with a keyboard mapped to a song, sound visuals,
 * and song managers. *)
let draw_song_player r =
  let keyboard_coords = draw_keyboard_visual r in
  let keyboard_x, keyboard_y, keyboard_w, keyboard_h = keyboard_coords in

  let arrows_w = keyboard_w / 6 in
  let arrows_x = keyboard_x + keyboard_w - arrows_w - 5 in
  let arrows_y = 21 * keyboard_h / 20 + keyboard_y in
  let arrows_h = draw_arrows r arrows_x arrows_y arrows_w in

  (*
   * draw the midi's load, play, pause, and stop buttons with the given bounds,
   * the height bound is calculated based on [w]. Returns the computed height.
   *)
  let midi_buttons = Model.get_midi_buttons() in
  let buttons_w = arrows_w * 2 in
  let buttons_x = keyboard_x in
  let buttons_y = arrows_y in
  let buttons_offset = buttons_w / (List.length midi_buttons) in
  let buttons_h = (100 - percent_key_padding) * buttons_offset / 100 in
  draw_horizontal_buttons midi_buttons r buttons_x buttons_y buttons_w buttons_h;


  let synth = Model.get_synth_button() in
  let synth_x = arrows_x in
  let synth_y = arrows_y + 5 * arrows_h / 4 in
  let synth_w = arrows_w -  arrows_w / 21 in
  let synth_h = synth_w / 5 in
  draw_button synth r synth_x synth_y synth_w synth_h;


  let bpm_y = arrows_y + arrows_h + 3 * keyboard_padding_h / 2 in
  let _ = draw_bpm r bpm_y in

  let scrub_y = buttons_y + buttons_h + 2 * keyboard_padding_h in
  let _ = draw_scrub r scrub_y in
  ()

(* draw the file chooser window, with file buttons, and select and
 * cancel buttons. *)
let draw_filechooser r =
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  let filename_buttons_x = window_w / 25 in
  let filename_buttons_y = window_h / 15 in
  let filename_buttons_w = window_h * 3 / 4 in
  let _ = draw_filename_buttons r filename_buttons_x filename_buttons_y filename_buttons_w in

  let file = Model.get_file_buttons() in
  let file_x = window_w - window_w / 5 in
  let file_y = window_h - window_h / 6 in
  let file_w = window_w / 5 in
  let file_offset = file_w / (List.length file) in
  let file_h = (100 - percent_key_padding) * file_offset / 100 in
  draw_horizontal_buttons file r file_x file_y file_w file_h

(* draw the visualizer window. This includes a keyboard mapped to tones,
 * a sound visualizer, and different ways to modify the tones. *)
let draw_synthesizer r =
  let keyboard_coords = draw_keyboard_visual r in
  let keyboard_x, keyboard_y, keyboard_w, keyboard_h = keyboard_coords in

  let grid = Model.get_synth_grid() in
  let grid_x = keyboard_x in
  let grid_y = 21 * keyboard_h / 20 + keyboard_y in
  let grid_w = keyboard_w / 6 - 10 in
  let grid_h = grid_w in
  draw_button grid r grid_x grid_y grid_w grid_h;

  let filters = Model.get_filter_buttons() in
  let filters_x = grid_x + 11 * grid_w / 10 in
  let filters_y = grid_y + 4 in
  let filters_w = 3 * grid_w / 4 in
  let filters_h = grid_h in
  draw_vertical_buttons filters r filters_x filters_y filters_w filters_h;

  let waves = Model.get_wave_buttons() in
  let waves_x = filters_x + 11 * filters_w / 10 in
  let waves_y = filters_y in
  let waves_w = filters_w in
  let waves_h = filters_h in
  draw_vertical_buttons waves r waves_x waves_y waves_w waves_h;

  let synth = Model.get_play_button() in
  let synth_w = grid_w in
  let synth_x = keyboard_x + keyboard_w - synth_w - 15 in
  let synth_y = grid_y in
  let synth_h = synth_w / 5 in
  draw_button synth r synth_x synth_y synth_w synth_h;

  let adsr_sliders_h = grid_y + 30 in
  let gap = (Model.get_height() - grid_y) / 6 in
  let _ = draw_adsr_sliders r adsr_sliders_h gap in
  ()

(* this is the main draw function of the gui. This will draw the current
 * window and should be called 60 times a second. *)
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
  let matched =
    match s with
    | "scrub" -> !scrub
    | "bpm" -> !bpm
    | "a_slider" -> !a_slider
    | "d_slider" -> !d_slider
    | "s_slider" -> !s_slider
    | "r_slider" -> !r_slider
    | _ -> None in
  match matched with
  | None -> false
  | Some rect ->
    let rect_x = Sdl.Rect.x rect in
    let rect_y = Sdl.Rect.y rect in
    let rect_w = Sdl.Rect.w rect in
    let rect_h = Sdl.Rect.h rect in
    rect_x <= x && x <= (rect_x+rect_w) && rect_y <= y && y <= (rect_y+rect_h)
