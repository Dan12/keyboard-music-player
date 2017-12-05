(* TODO needs comments for all functions and variables except draw *)

open Tsdl
open Keyboard_layout
open Keyboard
open Button
open File_button
open Model

let button_rects:((Sdl.rect * button) option array) =
  Array.make num_buttons None

let file_button_rects:((Sdl.rect * file_button) option array) =
  Array.make num_file_buttons None

let filename_button_rects:((Sdl.rect * filename_button) option array ref) =
  ref (Array.make (Model.get_num_filename_buttons ()) None)

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

let draw_button r x y size i button_with_state =
  let (button, state) = button_with_state in
  let rect = Gui_utils.draw_key_to_rect r x y size size keyboard_pressed_color key_background keyboard_border_color state in
  Array.set button_rects i (Some (rect, button));

  let padding = size / 5 in
  match button with
  | Load ->
    let font_size = 3 * size / 8 in
    Gui_utils.draw_text r (x + size/2) (y + size/2) font_size keyboard_text_color "Load"
  | Play ->
    let _ = Sdl.render_draw_line r (x+padding) (y+padding) (x+size-padding) (y+size/2) in
    let _ = Sdl.render_draw_line r (x+padding) (y+size-padding) (x+size-padding) (y+size/2) in
    let _ = Sdl.render_draw_line r (x+padding) (y+padding) (x+padding) (y+size-padding) in
    ()
  | Pause ->
    let rect_width = (size - 3 * padding) / 2 in
    let rect_height = size - 2 * padding in
    let left_rect = Sdl.Rect.create (x+padding) (y+padding) rect_width rect_height in
    let right_rect = Sdl.Rect.create (x+padding+rect_width+padding) (y+padding) rect_width rect_height in
    let _ = Sdl.render_draw_rects r [left_rect;right_rect] in
    ()
  | Stop ->
    let rect = Sdl.Rect.create (x+padding) (y+padding) (size-padding*2) (size-padding*2) in
    let _ = Sdl.render_draw_rect r (Some rect) in
    ()

let draw_buttons r x y w =
  let offset = w / num_buttons in
  let size = (100 - percent_key_padding) * offset / 100 in
  Array.iteri (fun i button ->
      let button_x = i * offset + x in
      draw_button r button_x y size i button
    ) (Model.get_buttons());
  size

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
  let should_noise = (*is_zero amplitudes 0*) true in
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

let draw_output r =
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  let keyboard = Model.get_keyboard () in
  let keyboard_layout = Model.get_keyboard_layout () in

  clear r;
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


  let arrows_w = keyboard_w / 6 in
  let arrows_x = keyboard_x + keyboard_w - arrows_w - 5 in
  let arrows_y = 21 * keyboard_h / 20 + keyboard_y in
  let _ = draw_arrows r keyboard arrows_x arrows_y arrows_w in


  let buttons_w = arrows_w * 2 in
  let buttons_x = keyboard_x in
  let buttons_y = arrows_y in
  let _ = draw_buttons r buttons_x buttons_y buttons_w in
  present r

let draw_file_button r x y size i file_button =
  let rect = Gui_utils.draw_key_to_rect r x (y + 2*size/5) size (size - 2*size/5) keyboard_pressed_color key_background keyboard_border_color KSUp in
  Array.set file_button_rects i (Some (rect, file_button));

  let font_size = 1 * size / 4 in
  match file_button with
  | Cancel ->
    Gui_utils.draw_text r (x + size/2) (y + ((size/3)*2)) font_size keyboard_text_color "Cancel"
  | Select ->
    Gui_utils.draw_text r (x + size/2) (y + ((size/3)*2)) font_size keyboard_text_color "Select"

let draw_file_buttons r x y w =
  let offset = w / num_file_buttons in
  let size = (100 - percent_key_padding) * offset / 100 in
  Array.iteri (fun i button ->
      let button_x = i * offset + x in
      draw_file_button r button_x y size i button
    ) (Model.get_file_buttons());
  size

let draw_filename_button r x y size i button_with_state =
  let (button, state) = button_with_state in
  let rect = Gui_utils.draw_key_to_rect r x y (size * 5) size keyboard_pressed_color key_background keyboard_border_color state in
  Array.set !filename_button_rects i (Some (rect, button));

  let font_size = 3 * size / 8 in
  Gui_utils.draw_text r (x + (3 * size / 2)) (y + size/2) font_size keyboard_text_color button

let draw_filename_buttons r x y w =
  let offset = w / ((Model.get_num_filename_buttons ())/2) in
  let size = (100 - percent_key_padding) * offset / 100 in
  let buttons = Model.get_filename_buttons() in
  let half = if (Array.length buttons) mod 2 = 0 then (Array.length buttons)/2 else ((Array.length buttons)/2)+1 in
  let first_half = Array.sub buttons 0 half in
  let second_half = Array.sub buttons half ((Array.length buttons) - half) in
  let final_i = ref 0 in
  Array.iteri (fun i button ->
      let button_y = i * offset + y in
      draw_filename_button r x button_y size i button;
      final_i := !final_i + 1
    ) first_half;
  Array.iteri (fun i button ->
      let button_y = i * offset + y in
      draw_filename_button r (x+(size*7)) button_y size (i + !final_i) button
    ) second_half;
  size

let draw_filechooser r =
  let num_files = Model.get_num_filename_buttons () in
  filename_button_rects := Array.make (num_files) None;
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  clear r;
  let filename_buttons_x = window_w / 25 in
  let filename_buttons_y = window_h / 15 in
  let filename_buttons_w = (window_h * 3 / 4) in
  let _ = draw_filename_buttons r filename_buttons_x filename_buttons_y filename_buttons_w in

  let buttons_x = window_w - (window_w / 5) in
  let buttons_y = window_h - (window_h / 6) in
  let buttons_w = (window_w / 5) in
  let _ = draw_file_buttons r buttons_x buttons_y buttons_w in
  present r

let draw r =
  match Model.get_state () with
  | SKeyboard -> draw_output r
  | SFileChooser -> draw_filechooser r
  | SSynthesizer -> ()

let button_pressed (x,y) =
  let button_rect_list = Array.to_list button_rects in
  let pressed_button_rect = List.find_opt (fun button_rect_option ->
      match button_rect_option with
      | None -> false
      | Some (rect, button) ->
        let rect_x = Sdl.Rect.x rect in
        let rect_y = Sdl.Rect.y rect in
        let rect_w = Sdl.Rect.w rect in
        let rect_h = Sdl.Rect.h rect in
        rect_x <= x && x <= (rect_x+rect_w) && rect_y <= y && y <= (rect_y+rect_h)
    ) button_rect_list in
  match pressed_button_rect with
  | Some (Some (rect, button)) -> Some button
  | _ -> None

let file_button_pressed (x,y) =
  let file_button_rect_list = Array.to_list file_button_rects in
  let pressed_button_rect = List.find_opt (fun button_rect_option ->
      match button_rect_option with
      | None -> false
      | Some (rect, button) ->
        let rect_x = Sdl.Rect.x rect in
        let rect_y = Sdl.Rect.y rect in
        let rect_w = Sdl.Rect.w rect in
        let rect_h = Sdl.Rect.h rect in
        rect_x <= x && x <= (rect_x+rect_w) && rect_y <= y && y <= (rect_y+rect_h)
    ) file_button_rect_list in
  match pressed_button_rect with
  | Some (Some (rect, button)) -> Some button
  | _ -> None

let filename_button_pressed (x,y) =
  let filename_button_rect_list = Array.to_list !filename_button_rects in
  let pressed_filename_button_rect = List.find_opt (fun button_rect_option ->
      match button_rect_option with
      | None -> false
      | Some (rect, button) ->
        let rect_x = Sdl.Rect.x rect in
        let rect_y = Sdl.Rect.y rect in
        let rect_w = Sdl.Rect.w rect in
        let rect_h = Sdl.Rect.h rect in
        rect_x <= x && x <= (rect_x+rect_w) && rect_y <= y && y <= (rect_y+rect_h)
    ) filename_button_rect_list in
  match pressed_filename_button_rect with
  | Some (Some (rect, button)) -> Some button
  | _ -> None






























(*
let create_midi_buttons () =
  let current_pressed = ref 3 in
  let play_up _ =
    current_pressed := 1;
    Model.start_midi() in
  let rec play = Button.create_button ignore play_up play_draw
  and play_draw (r:Tsdl.Sdl.renderer) =
    let (x, y, w, h) = Button.get_area play in

    let state = if !current_pressed = 1 then KSDown else KSUp in
    draw_key r x y w h state;

    let w_padding = w / 5 in
    let h_padding = h / 5 in

    let _ = Sdl.render_draw_line r (x+w_padding) (y+h_padding) (x+w-w_padding) (y+h/2) in
    let _ = Sdl.render_draw_line r (x+w_padding) (y+h-h_padding) (x+w-w_padding) (y+h/2) in
    let _ = Sdl.render_draw_line r (x+w_padding) (y+h_padding) (x+w_padding) (y+h-h_padding) in
    () in
  [play] *)
