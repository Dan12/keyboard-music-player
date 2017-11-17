open Tsdl
open Tsdl_ttf

let fonts = Hashtbl.create 16

let percent_key_padding = 10

let background_color = Sdl.Color.create 255 255 255 255
let keyboard_text_color = Sdl.Color.create 0 0 0 255
let keyboard_border_color = Sdl.Color.create 0 0 0 255

type key =
  | String of string
  | Shift
  | Enter
  | Empty

let (>>=) o f = match o with
  | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

let get_font size =
  match Hashtbl.find_opt fonts size with
  | None -> Ttf.open_font "resources/agane.ttf" size >>= fun font ->
    Hashtbl.add fonts size font;
    print_endline "here";
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


let draw_key r x y w h font key =
  set_color r keyboard_border_color;
  let rect = Sdl.Rect.create x y w h in
  let _ = Sdl.render_draw_rect r (Some rect) in
  draw_key_text r x y w h font key

(*
 * Assumes the key list has length of [row] * [col]
 *)
let draw_keyboard renderer x y w row col keys =
  let next_key = ref keys in
  let curr_x = ref x in
  let curr_y = ref y in
  let offset = w / col in
  let key_size = (100 - percent_key_padding) * offset / 100 in
  let font = get_font (7 * key_size / 10) in
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
  String "1"::
  String "2"::
  String "3"::
  String "4"::
  String "5"::
  String "6"::
  String "7"::
  String "8"::
  String "9"::
  String "0"::
  String "-"::
  String "="::
  String "Q"::
  String "W"::
  String "E"::
  String "R"::
  String "T"::
  String "Y"::
  String "U"::
  String "I"::
  String "O"::
  String "P"::
  String "["::
  String "]"::
  String "A"::
  String "S"::
  String "D"::
  String "F"::
  String "G"::
  String "H"::
  String "J"::
  String "K"::
  String "L"::
  String ";"::
  String "'"::
  Enter::
  String "Z"::
  String "X"::
  String "C"::
  String "V"::
  String "B"::
  String "N"::
  String "M"::
  String ","::
  String "."::
  String "/"::
  Shift::
  Empty::
  []

let draw r =
  clear r;
  draw_keyboard r 20 20 1200 4 12 (get_keyboard_keys ());
  present r
