open Tsdl
open Tsdl_ttf

let percent_key_padding = 10

let background_color = Sdl.Color.create 255 255 255 255
let keyboard_text_color = Sdl.Color.create 0 0 0 255
let keyboard_border_color = Sdl.Color.create 0 0 0 255

let create_font = Ttf.open_font "agane.ttf"

type key =
  | String of string
  | Shift
  | Enter
  | Empty

let (>>=) o f = match o with
  | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

let set_color r color =
  let red = Sdl.Color.r color in
  let green = Sdl.Color.g color in
  let blue = Sdl.Color.b color in
  let _ = Sdl.set_render_draw_color r red green blue 255 in
  ()

let draw_text r x y font str =
  (* defines the bounds of the font *)
  Ttf.size_utf8 font str >>= fun (text_w, text_h) ->
  let text_rect = Sdl.Rect.create 100 100 text_w text_h in
  Ttf.render_text_solid font str keyboard_text_color >>= fun (sface) ->
  Sdl.create_texture_from_surface r sface >>= fun (font_texture) ->
  let _ = Sdl.render_copy ~dst:text_rect r font_texture in
  ()

let draw_key_text r x y width height font = function
  | String s -> draw_text r x y font s
  | Shift -> ()
  | Enter -> ()
  | Empty -> ()


let draw_key r x y width height font key =
  set_color r keyboard_border_color;
  let rect = Sdl.Rect.create x y width height in
  let _ = Sdl.render_draw_rect r (Some rect) in
  draw_key_text r x y width height font key

(*
 * Assumes the key list has length of [row] * [col]
 *)
let draw_keyboard (renderer:Tsdl.Sdl.renderer) (x:int) (y:int) (width:int) (row:int) (col:int) (keys:key list) =
  let next_key = ref keys in
  let curr_x = ref x in
  let curr_y = ref y in
  let offset = width / col in
  let key_size = (100 - percent_key_padding) * offset / 100 in
  create_font (7 * key_size / 10) >>= fun font ->
  for r = 1 to row do
    for c = 1 to col do
      draw_key renderer !curr_x !curr_y key_size key_size font (List.hd !next_key);
      next_key := List.tl !next_key;
      curr_x := !curr_x + offset
    done;
    curr_x := x;
    curr_y := !curr_y + offset
  done

let clear r =
  set_color r background_color;
  let _ = Sdl.render_clear r in
  ()

(* flush the buffer *)
let present r =
  let _ = Sdl.render_present r in
  ()

let get_keyboard_keys () =
  let rec es = (String "A")::es in
  es

let draw r =
  clear r;
  draw_keyboard r 20 20 1200 4 12 (get_keyboard_keys ());
  present r
