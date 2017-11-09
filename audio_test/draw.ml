open Tsdl
open Result

let (>>=) o f =
match o with | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
             | Ok a -> f a

let frame = ref 0
let prev_time = ref 0.
let refresh_rate = 0.035 (* refresh every 35ms *)

let draw r = 
  let cur_time = Unix.gettimeofday () in
  if cur_time -. (!prev_time) > refresh_rate then
    (prev_time := cur_time;
    frame := !frame + 4;

    (* set clear color *)
    let _ = Sdl.set_render_draw_color r 0 0 0 0 in
    (* clear the buffer *)
    let _ = Sdl.render_clear r in
    (* set the color to yellow *)
    let _ = Sdl.set_render_draw_color r 255 (!frame mod 256) 0 255 in
    (* draw lines *)
    let _ = Sdl.render_draw_line r 50 50 100 100 in
    let _ = Sdl.render_draw_line r 150 50 100 100 in
    let vert = (170+(!frame mod 200)) in
    let rect = Sdl.Rect.create vert vert 100 100 in
    let _ = Sdl.render_fill_rect r (Some rect) in
    
    (* flush the buffer *)
    Sdl.render_present r)
  else 
    ()