open Tsdl
open Tsdl_ttf
open Keyboard
open Keyboard_layout

(* binds a Tsdl option with it's returning object, should never fail *)
let (>>=) o f = match o with
  | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

(* cache used fonts so we don't need to reload every time they are used *)
let fonts = Hashtbl.create 16

(* returns a font with the specified font size *)
let get_font size =
  match Hashtbl.find_opt fonts size with
  | None -> Ttf.open_font "resources/agane.ttf" size >>= fun font ->
    Hashtbl.add fonts size font;
    font
  | Some font -> font


(* set the currently used color in the renderer to [color] *)
let set_color r color =
  let red = Sdl.Color.r color in
  let green = Sdl.Color.g color in
  let blue = Sdl.Color.b color in
  let alpha = Sdl.Color.a color in
  Sdl.set_render_draw_color r red green blue alpha |> ignore


(* draw the requested [str] text with the specified [color] and font size [size]
 * centered at the point ([x], [y])*)
let draw_text r x y font_size color str =
  let font = get_font font_size in
  (* defines the bounds of the font *)
  Ttf.size_utf8 font str >>= fun (text_w, text_h) ->
  (* 2/5 will lower the text by 10% *)
  let text_rect = Sdl.Rect.create (x - text_w / 2) (y - 2 * text_h / 5) text_w text_h in
  Ttf.render_text_solid font str color >>= fun (sface) ->
  Sdl.create_texture_from_surface r sface >>= fun (font_texture) ->
  let _ = Sdl.render_copy ~dst:text_rect r font_texture in
  Sdl.free_surface sface;
  Sdl.destroy_texture font_texture

(* draw the visualization of the shift key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_shift r x y w h =
  let _ = Sdl.render_draw_line r x (y + h / 2) (x + w / 2) y in
  let _ = Sdl.render_draw_line r (x + w / 2) y (x + w) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + w) (y + h / 2) (x + 3 * w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h / 2) (x + 3 * w / 4) (y + h) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h) (x + w / 4) (y + h) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h) (x + w / 4) (y + h / 2) in
  Sdl.render_draw_line r (x + w / 4) (y + h / 2) x (y + h / 2) |> ignore

(* draw the visualization of the enter key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_enter r x y w h =
  let _ = Sdl.render_draw_line r x (y + 2 * h / 3) (x + w / 4) (y + h / 3) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 3) (x + w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 2) (x + 3 * w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h / 2) (x + 3 * w / 4) y in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) y (x + w) y in
  let _ = Sdl.render_draw_line r (x + w) y (x + w) (y + 5 * h / 6) in
  let _ = Sdl.render_draw_line r (x + w) (y + 5 * h / 6) (x + w / 4) (y + 5 * h / 6) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + 5 * h / 6) (x + w / 4) (y + h) in
  Sdl.render_draw_line r (x + w / 4) (y + h) x (y + 2 * h / 3) |> ignore

(* draw the visualization of the left arrow key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_left r x y w h =
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 2) (x + 3 * w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 2) (x + w / 2) (y + 3 * h / 4) in
  Sdl.render_draw_line r (x + w / 4) (y + h / 2) (x + w / 2) (y + h / 4) |> ignore

(* draw the visualization of the down arrow key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_down r x y w h =
  let _ = Sdl.render_draw_line r (x + w / 2) (y + 3 * h / 4) (x + w / 2) (y + h / 4) in
  let _ = Sdl.render_draw_line r (x + w / 2) (y + 3 * h / 4) (x + w / 3) (y + h / 2) in
  Sdl.render_draw_line r (x + w / 2) (y + 3 * h / 4) (x + 2 * w / 3) (y + h / 2) |> ignore

(* draw the visualization of the up arrow key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_up r x y w h =
  let _ = Sdl.render_draw_line r (x + w / 2) (y + h / 4) (x + w / 2) (y + 3 * h / 4) in
  let _ = Sdl.render_draw_line r (x + w / 2) (y + h / 4) (x + w / 3) (y + h / 2) in
  Sdl.render_draw_line r (x + w / 2) (y + h / 4) (x + 2 * w / 3) (y + h / 2) |> ignore

(* draw the visualization of the right arrow key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_right r x y w h =
  let _ = Sdl.render_draw_line r (x + w / 4) (y + h / 2) (x + 3 * w / 4) (y + h / 2) in
  let _ = Sdl.render_draw_line r (x + 3 * w / 4) (y + h / 2) (x + w / 2) (y + 3 * h / 4) in
  Sdl.render_draw_line r (x + 3 * w / 4) (y + h / 2) (x + w / 2) (y + h / 4) |> ignore

(* draw the visualization of the play triangle in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_play r x y w h =
  let w_padding = w / 5 in
  let h_padding = h / 5 in

  let _ = Sdl.render_draw_line r (x+w_padding) (y+h_padding) (x+w-w_padding) (y+h/2) in
  let _ = Sdl.render_draw_line r (x+w_padding) (y+h-h_padding) (x+w-w_padding) (y+h/2) in
  Sdl.render_draw_line r (x+w_padding) (y+h_padding) (x+w_padding) (y+h-h_padding) |> ignore

(* draw the visualization of the pause bars in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_pause r x y w h =
  let w_padding = w / 5 in
  let h_padding = h / 5 in

  let rect_width = (w - 3 * w_padding) / 2 in
  let rect_height = h - 2 * h_padding in
  let left_rect = Sdl.Rect.create (x+w_padding) (y+h_padding) rect_width rect_height in
  let right_rect = Sdl.Rect.create (x+rect_width+2*w_padding) (y+h_padding) rect_width rect_height in
  Sdl.render_draw_rects r [left_rect;right_rect] |> ignore

(* draw the visualization of the stop square in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_stop r x y w h =
  let w_padding = w / 5 in
  let h_padding = h / 5 in

  let rect = Sdl.Rect.create (x+w_padding) (y+h_padding) (w-w_padding*2) (h-h_padding*2) in
  Sdl.render_draw_rect r (Some rect) |> ignore


(* draw a key's text in the bounding box ([x], [y]) - ([x] + [w], [y] + [h]).
 * The text is based on the key type *)
let draw_key_text r x y w h font_size text_color = function
  | String s -> draw_text r (x + w / 2) (y + h / 2) font_size text_color s
  | Shift -> draw_shift r (x  + w / 4) (y + h / 4) (w / 2) (h / 2)
  | Enter -> draw_enter r (x  + w / 4) (y + h / 4) (w / 2) (h / 2)
  | Empty -> ()



(* draw a pressed or unpressed key in the bounding box
 * ([x], [y]) - ([x] + [w], [y] + [h]) *)
let draw_key r x y w h down_color up_color boarder_color key_state =
  (match key_state with
   | KSDown -> set_color r down_color;
     let rect = Sdl.Rect.create x y w h in
     Sdl.render_fill_rect r (Some rect) |> ignore
   | _ -> set_color r up_color;
     let rect = Sdl.Rect.create x y w h in
     Sdl.render_fill_rect r (Some rect) |> ignore);

  set_color r boarder_color;
  let rect = Sdl.Rect.create x y w h in
  Sdl.render_draw_rect r (Some rect) |> ignore
