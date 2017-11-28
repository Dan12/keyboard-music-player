open Tsdl
open Tsdl_ttf
open Keyboard_layout
open Keyboard
open Button

let button_rects:((Sdl.rect * button) option array) =
  Array.make (List.length buttons) None

let fonts = Hashtbl.create 16

let percent_key_padding = 10
let arrow_width_height_ratio = 2

let background_color = Sdl.Color.create 255 255 255 255
let keyboard_text_color = Sdl.Color.create 0 0 0 255
let keyboard_border_color = Sdl.Color.create 0 0 0 255
let keyboard_pressed_color = Sdl.Color.create 128 128 255 255

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
  let _ = Sdl.set_render_draw_color r red green blue 255 in
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


let draw_key r x y w h key_state =
  (match key_state with
   | KSDown -> set_color r keyboard_pressed_color;
     let rect = Sdl.Rect.create x y w h in
     let _ = Sdl.render_fill_rect r (Some rect) in
     ()
   | _ -> ());
  set_color r keyboard_border_color;
  let rect = Sdl.Rect.create x y w h in
  let _ = Sdl.render_draw_rect r (Some rect) in
  ()

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

  (* let left_state = Keyboard.get_state_arrow 0 keyboard in
  let up_state = Keyboard.get_state_arrow 1 keyboard in
  let down_state = Keyboard.get_state_arrow 2 keyboard in
  let right_state = Keyboard.get_state_arrow 3 keyboard in *)

  (* draw left *)
  (* draw_key r x (y + y_offset) w_key h_key left_state; *)
  let _ = Sdl.render_draw_line r (x + w_key / 4) (y + y_offset + h_key / 2) (x + 3 * w_key / 4) (y + y_offset + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + w_key / 4) (y + y_offset + h_key / 2) (x + w_key / 2) (y + y_offset + 3 * h_key / 4) in
  let _ = Sdl.render_draw_line r (x + w_key / 4) (y + y_offset + h_key / 2) (x + w_key / 2) (y + y_offset + h_key / 4) in

  (* draw down *)
  (* draw_key r (x + x_offset) (y + y_offset) w_key h_key down_state; *)
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) (x + x_offset + w_key / 2) (y + y_offset + h_key / 4) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) (x + x_offset + w_key / 3) (y + y_offset + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) (x + x_offset + 2 * w_key / 3) (y + y_offset + h_key / 2) in

  (* draw up *)
  (* draw_key r (x + x_offset) y w_key h_key up_state; *)
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + h_key / 4) (x + x_offset + w_key / 2) (y + 3 * h_key / 4) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + h_key / 4) (x + x_offset + w_key / 3) (y + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + x_offset + w_key / 2) (y + h_key / 4) (x + x_offset + 2 * w_key / 3) (y + h_key / 2) in

  (* draw right *)
  (* draw_key r (x + 2 * x_offset) (y + y_offset) w_key h_key right_state; *)
  let _ = Sdl.render_draw_line r (x + 2 * x_offset + w_key / 4) (y + y_offset + h_key / 2) (x + 2 * x_offset + 3 * w_key / 4) (y + y_offset + h_key / 2) in
  let _ = Sdl.render_draw_line r (x + 2 * x_offset + 3 * w_key / 4) (y + y_offset + h_key / 2) (x + 2 * x_offset + w_key / 2) (y + y_offset + 3 * h_key / 4) in
  let _ = Sdl.render_draw_line r (x + 2 * x_offset + 3 * w_key / 4) (y + y_offset + h_key / 2) (x + 2 * x_offset + w_key / 2) (y + y_offset + h_key / 4) in
  2 * y_offset

let draw_button r x y size i button =
  let rect = Sdl.Rect.create x y size size in
  Array.set button_rects i (Some (rect, button));
  let _ = Sdl.render_draw_rect r (Some rect) in
  match button with
  | Load ->
    let font = get_font (3 * size / 8) in
    draw_text r (x + size/2) (y + size/2) font "Load"
  | Play ->
    let padding = size / 5 in
    let _ = Sdl.render_draw_line r (x+padding) (y+padding) (x+size-padding) (y+size/2) in
    let _ = Sdl.render_draw_line r (x+padding) (y+size-padding) (x+size-padding) (y+size/2) in
    let _ = Sdl.render_draw_line r (x+padding) (y+padding) (x+padding) (y+size-padding) in
    ()
  | Pause ->
    let padding = size / 5 in
    let rect_width = (size - 3 * padding) / 2 in
    let rect_height = size - 2 * padding in
    let left_rect = Sdl.Rect.create (x+padding) (y+padding) rect_width rect_height in
    let right_rect = Sdl.Rect.create (x+padding+rect_width+padding) (y+padding) rect_width rect_height in
    let _ = Sdl.render_draw_rects r [left_rect;right_rect] in
    ()

let draw_buttons r x y w =
  let offset = w / (List.length buttons) in
  let size = (100 - percent_key_padding) * offset / 100 in
  List.iteri (fun i button ->
      let button_x = i * offset + x in
      draw_button r button_x y size i button
    ) buttons;
  size

let clear r =
  set_color r background_color;
  let _ = Sdl.render_clear r in
  ()

(* flush the buffer *)
let present r =
  let _ = Sdl.render_present r in
  ()

let draw keyboard_layout keyboard r =
  clear r;
  let init_x = 20 in

  let keyboard_y = 20 in
  let keyboard_w = 1200 in
  let keyboard_rows = Keyboard_layout.get_rows keyboard_layout in
  let keyboard_cols = Keyboard_layout.get_cols keyboard_layout in
  let keyboard_h = draw_keyboard r keyboard_layout keyboard
      init_x keyboard_y keyboard_w keyboard_rows keyboard_cols in

  let arrows_w = keyboard_w / 6 in
  let arrows_x = init_x + keyboard_w / 2 - arrows_w / 2 in
  let arrows_y = 21 * keyboard_h / 20 + keyboard_y in
  let arrows_h = draw_arrows r keyboard arrows_x arrows_y arrows_w in

  let buttons_w = arrows_w in
  let buttons_x = arrows_x in
  let buttons_y = 22 * arrows_h / 20 + arrows_y in
  let buttons_h = draw_buttons r buttons_x buttons_y buttons_w in
  present r

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
  | Some (Some (_, button)) -> Some button
  | _ -> None
