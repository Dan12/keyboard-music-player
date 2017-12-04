(* TODO needs comments for all functions and variables except draw *)

open Tsdl
open Tsdl_ttf
open Keyboard_layout
open Keyboard
open Button
open File_button
open Model

let scrub:(Sdl.rect option ref) = ref None

let button_rects:((Sdl.rect * button) option array) =
  Array.make num_buttons None

let file_button_rects:((Sdl.rect * file_button) option array) =
  Array.make num_file_buttons None

let filename_button_rects:((Sdl.rect * filename_button) option array ref) =
  ref (Array.make (Model.get_num_filename_buttons ()) None)

let fonts = Hashtbl.create 16

let keyboard_padding_w = 20
let keyboard_padding_h = 30
let percent_key_padding = 10

let arrow_width_height_ratio = 2

let graphic_padding_w = 25
let graphic_padding_h = 20
let percent_graphic_padding = 16
let max_amplitude = 60

let black = Sdl.Color.create 0 0 0 255
let red = Sdl.Color.create 204 24 30 255

let background_color = Sdl.Color.create 255 255 255 255
let keyboard_text_color = Sdl.Color.create 0 0 0 255
let keyboard_border_color = Sdl.Color.create 0 0 0 255
let keyboard_pressed_color = Sdl.Color.create 90 90 255 255

let min_graphic_color = Sdl.Color.create 0 255 0 255
let max_graphic_color = Sdl.Color.create 255 0 0 255

let key_background = Sdl.Color.create 255 255 255 220

let (>>=) o f = match o with
  | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

let get_font size =
  match Hashtbl.find_opt fonts size with
  | None -> Ttf.open_font "resources/agane.ttf" size >>= fun font ->
    Hashtbl.add fonts size font;
    font
  | Some font -> font

let set_color r color =
  let red = Sdl.Color.r color in
  let green = Sdl.Color.g color in
  let blue = Sdl.Color.b color in
  let alpha = Sdl.Color.a color in
  let _ = Sdl.set_render_draw_color r red green blue alpha in
  ()

let draw_text r x y font str =
  (* defines the bounds of the font *)
  Ttf.size_utf8 font str >>= fun (text_w, text_h) ->
  (* 2/5 will lower the text by 10% *)
  let text_rect = Sdl.Rect.create (x - text_w / 2) (y - 2 * text_h / 5) text_w text_h in
  Ttf.render_text_solid font str keyboard_text_color >>= fun (sface) ->
  Sdl.create_texture_from_surface r sface >>= fun (font_texture) ->
  let _ = Sdl.render_copy ~dst:text_rect r font_texture in
  let () = Sdl.free_surface sface in
  Sdl.destroy_texture font_texture

let draw_shift r x y w h =
  let _ = Sdl.render_draw_line r x (y + h / 2) (x + w / 2) y in
  let _ = Sdl.render_draw_line r (x + w / 2) y (x + w) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + w) (y + h / 2) (x + 3 * w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h / 2) (x + 3 * w / 4) (y + h) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h) (x + w / 4) (y + h) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h) (x + w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 2) x (y + h / 2) in
  ()

let draw_enter r x y w h =
  let _ = Sdl.render_draw_line r x (y + 2 * h / 3) (x + w / 4) (y + h / 3) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 3) (x + w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 2) (x + 3 * w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h / 2) (x + 3 * w / 4) y in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) y (x + w) y in
  let _ = Sdl.render_draw_line r (x + w) y (x + w) (y + 5 * h / 6) in
  let _ = Sdl.render_draw_line r (x + w) (y + 5 * h / 6) (x + w / 4) (y + 5 * h / 6) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + 5 * h / 6) (x + w / 4) (y + h) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h) x (y + 2 * h / 3) in
  ()

let draw_key_text r x y w h font = function
  | String s -> draw_text r (x + w / 2) (y + h / 2) font s
  | Shift -> draw_shift r (x  + w / 4) (y + h / 4) (w / 2) (h / 2)
  | Enter -> draw_enter r (x  + w / 4) (y + h / 4) (w / 2) (h / 2)
  | Empty -> ()

let draw_key_to_rect r x y w h key_state =

  (match key_state with
  | KSDown -> set_color r keyboard_pressed_color;
    let rect = Sdl.Rect.create x y w h in
    let _ = Sdl.render_fill_rect r (Some rect) in
    ()
  | _ -> set_color r key_background;
    let rect = Sdl.Rect.create x y w h in
    let _ = Sdl.render_fill_rect r (Some rect) in
    ());

  set_color r keyboard_border_color;
  let rect = Sdl.Rect.create x y w h in
  let _ = Sdl.render_draw_rect r (Some rect) in
  rect

let draw_key r x y w h key_state =
  draw_key_to_rect r x y w h key_state |> ignore

(*
 * Assumes the key list has length of [row] * [col]
 *)
let draw_keyboard renderer keyboard_layout keyboard x y w rows cols =
  let offset = w / cols in
  let key_size = (100 - percent_key_padding) * offset / 100 in
  let font = get_font (7 * key_size / 10) in
  for r = 0 to rows - 1 do
    for c = 0 to cols - 1 do
      let key_visual = Keyboard_layout.get_visual (r, c) keyboard_layout in
      let key_state = Keyboard.get_state (r, c) keyboard in
      let curr_x = c * offset + x in
      let curr_y = r * offset + y in
      draw_key renderer curr_x curr_y key_size key_size key_state;
      draw_key_text renderer curr_x curr_y key_size key_size font key_visual
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
  draw_key r x (y + y_offset) w_key h_key left_state;
  let _ = Sdl.render_draw_line r (x + w_key / 4) (y + y_offset + h_key / 2) (x + 3 * w_key / 4) (y + y_offset + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + w_key / 4) (y + y_offset + h_key / 2) (x + w_key / 2) (y + y_offset + 3 * h_key / 4) in
  let _ = Sdl.render_draw_line r (x + w_key / 4) (y + y_offset + h_key / 2) (x + w_key / 2) (y + y_offset + h_key / 4) in

  (* draw down *)
  draw_key r (x + x_offset) (y + y_offset) w_key h_key down_state;
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) (x + x_offset + w_key / 2) (y + y_offset + h_key / 4) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) (x + x_offset + w_key / 3) (y + y_offset + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) (x + x_offset + 2 * w_key / 3) (y + y_offset + h_key / 2) in

  (* draw up *)
  draw_key r (x + x_offset) y w_key h_key up_state;
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + h_key / 4) (x + x_offset + w_key / 2) (y + 3 * h_key / 4) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + h_key / 4) (x + x_offset + w_key / 3) (y + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + h_key / 4) (x + x_offset + 2 * w_key / 3) (y + h_key / 2) in

  (* draw right *)
  draw_key r (x + 2 * x_offset) (y + y_offset) w_key h_key right_state;
  let _ = Sdl.render_draw_line r (x + 2 * x_offset + w_key / 4) (y + y_offset + h_key / 2) (x + 2 * x_offset + 3 * w_key / 4) (y + y_offset + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + 2 * x_offset + 3 * w_key / 4) (y + y_offset + h_key / 2) (x + 2 * x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) in
  let _ = Sdl.render_draw_line r (x + 2 * x_offset + 3 * w_key / 4) (y + y_offset + h_key / 2) (x + 2 * x_offset + w_key / 2) (y + y_offset + h_key / 4) in
  2 * y_offset

let draw_button r x y size i button_with_state =
  let (button, state) = button_with_state in
  let rect = draw_key_to_rect r x y size size state in
  Array.set button_rects i (Some (rect, button));

  let padding = size / 5 in
  match button with
  | Load ->
    let font = get_font (3 * size / 8) in
    draw_text r (x + size/2) (y + size/2) font "Load"
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
  set_color r red;
  let played_line = Sdl.Rect.create scrub_start_x line_y
      (scrub_pos - scrub_start_x) line_h in
  let _ = Sdl.render_fill_rect r (Some played_line) in
  set_color r black;
  let remaining_line = Sdl.Rect.create scrub_pos line_y
      (scrub_end_x - scrub_pos) line_h in
  let _ = Sdl.render_fill_rect r (Some remaining_line) in

  (* draw the scrub from ealier last. *)
  set_color r black;
  let _ = Sdl.render_fill_rect r (Some rect) in
  ()

let clear r =
  set_color r background_color;
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
  set_color r segment_color;
  let rect = Sdl.Rect.create x y w h in
  let _ = Sdl.render_fill_rect r (Some rect) in
  ()

let draw_graphics r amplitudes x y w h =
  let num_bars = Array.length amplitudes in
  let offset = (w + num_bars / 2) / num_bars in
  let bar_w = (100 - percent_graphic_padding) * offset / 100 in
  let segment_h = (h + max_amplitude / 2) / max_amplitude in
  for height = 0 to max_amplitude do
    for bar = 0 to num_bars - 1 do
      let segment_x = x + bar * offset in
      let segment_y = (y + h) - (height + 1) * segment_h in
      if height <= amplitudes.(bar) || (height = 1 && Random.int 2 = 1)
      then draw_graphic_segment r height segment_x segment_y bar_w segment_h
      else ()
    done;
  done

let get_amplitudes () =
  let complex_arr = Model.get_buffer () in

  let normalize = fun compl ->
    int_of_float (2.0 *. (Complex.norm compl))
  in

  let mapped = Array.map normalize complex_arr in
  let init_i i =
    mapped.(i)
  in
  Array.init 32 init_i

  (* let complex_arr = Model.get_buffer () in
  print_endline (string_of_int (Array.length complex_arr));

  let arr = Array.make 30 0 in
  for i = 0 to Array.length arr - 1 do
    arr.(i) <- Random.int 61
  done;
  arr *)

let draw_output r =
  let window_w = Model.get_width () in
  let window_h = Model.get_height () in

  let keyboard = Model.get_keyboard () in
  let keyboard_layout = Model.get_keyboard_layout () in

  clear r;
  let amplitudes = get_amplitudes () in
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
  let arrows_x = keyboard_padding_w + keyboard_w / 2 - arrows_w / 2 in
  let arrows_y = 21 * keyboard_h / 20 + keyboard_y in
  let arrows_h = draw_arrows r keyboard arrows_x arrows_y arrows_w in

  let buttons_w = arrows_w * 2 in
  let buttons_x = keyboard_padding_w + keyboard_w / 2 - buttons_w / 2 in
  let buttons_y = 22 * arrows_h / 20 + arrows_y in
  let buttons_h = draw_buttons r buttons_x buttons_y buttons_w in

  let scrub_y = buttons_y + buttons_h + keyboard_padding_h / 5 in
  let _ = draw_scrub r scrub_y in
  present r

let draw_file_button r x y size i file_button =
  let rect = draw_key_to_rect r x (y + ((size/5)*2)) size (size - ((size/5)*2)) KSUp in
  Array.set file_button_rects i (Some (rect, file_button));

  let font = get_font (1 * size / 4) in
  match file_button with
  | Cancel ->
    draw_text r (x + size/2) (y + ((size/3)*2)) font "Cancel"
  | Select ->
    draw_text r (x + size/2) (y + ((size/3)*2)) font "Select"

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
  let rect = draw_key_to_rect r x y (size * 5) size state in
  Array.set !filename_button_rects i (Some (rect, button));

  let font = get_font (3 * size / 8) in
  draw_text r (x + (3 * size / 2)) (y + size/2) font button

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

let scrub_pressed (x,y) =
  match !scrub with
  | None -> false
  | Some rect ->
    let rect_x = Sdl.Rect.x rect in
    let rect_y = Sdl.Rect.y rect in
    let rect_w = Sdl.Rect.w rect in
    let rect_h = Sdl.Rect.h rect in
    rect_x <= x && x <= (rect_x+rect_w) && rect_y <= y && y <= (rect_y+rect_h)
