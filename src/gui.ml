open Tsdl

let percent_key_padding = 10

type key =
  | Character of char
  | Shift
  | Enter
  | Empty

let draw_key (r:Tsdl.Sdl.renderer) (x:int) (y:int) (width:int) (height:int) (key:key) =
  let _ = Sdl.set_render_draw_color r 0 0 0 255 in
  let rect = Sdl.Rect.create x y width height in
  let _ = Sdl.render_draw_rect r (Some rect) in
  (* TODO add key into center of rectangle *)
  ()

(*
 * Assumes the key list has length of [row] * [col]
 *)
let draw_keyboard (renderer:Tsdl.Sdl.renderer) (x:int) (y:int) (width:int) (height:int) (row:int) (col:int) (keys:key list) =
  let next_key = ref keys in
  let curr_x = ref x in
  let curr_y = ref y in
  let off_x = width / col in
  let key_width = (100 - percent_key_padding) * off_x / 100 in
  let off_y = height / row in
  let key_height = (100 - percent_key_padding) * off_y / 100 in
  for r = 1 to row do
    for c = 1 to col do
      draw_key renderer !curr_x !curr_y key_width key_height (List.hd !next_key);
      next_key := List.tl !next_key;
      curr_x := !curr_x + off_x
    done;
    curr_x := x;
    curr_y := !curr_y + off_y
  done


let draw r =
  let _ = Sdl.set_render_draw_color r 255 255 255 255 in
  let _ = Sdl.render_clear r in
  let rec es = Empty::es in
  draw_keyboard r 20 20 600 200 4 12 es;
  (* flush the buffer *)
  let _ = Sdl.render_present r in
  ()
