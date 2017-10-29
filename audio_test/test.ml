(* Sample code provided by @psqu in issue #13. *)

open Tsdl
open Result
open Tsdl_ttf

let audio_freq    = 44100
let audio_samples = 4096
let time = ref 0

let audiofile = ref None

let (>>=) o f =
match o with | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
             | Ok a -> f a

let audio_callback output =
  (* output is 2*audio samples *)
  let open Bigarray in
  (* generate the next audio sample *)
  (* output dim is 2*4096 *)
  for i = 0 to ((Array1.dim output / 2) - 1) do
    let (samplel, sampler) = match !audiofile with
    | Some arr when (!time*2+1 < Array1.dim arr) -> (Int32.of_int(arr.{!time*2} lsl 16), Int32.of_int(arr.{!time*2+1} lsl 16))
    | Some arr -> let _ = Sdl.free_wav arr in let _ = audiofile := None in (Int32.of_int 0, Int32.of_int 0)
    | None ->
      let _ = ((float_of_int !time) /.
                  (66100.0 +.
                    1000.0 *. sin (0.0001 *. (float_of_int !time)))) *. 3000.0
      in
      let phase = (float_of_int !time) *. 0.06 in
      (* 1073741823 = 2^30, amplitude, volume = 1.0 is 50% max volume *)
      let volume = 1. in
      let s = Int32.of_float ((sin phase) *. 1073741823.0 *. volume) in
      (s,s)
    in
    begin
      (* 2 channel audio, channels go next to each other *)
      output.{ 2 * i     } <- samplel;
      output.{ 2 * i + 1 } <- sampler;
      time := !time + 1
    end
  done

let audio_callback =
  ref (Some (Sdl.audio_callback Bigarray.int32 audio_callback))

let audio_setup () =
  let wav_audio_spec = { Sdl.as_freq = audio_freq;
    as_format = Sdl.Audio.s16;
    Sdl.as_channels = 2;
    Sdl.as_samples = audio_samples;
    Sdl.as_silence = 0;
    Sdl.as_size =
      (* size of buffer in bytes (samples*channels*bytes per int) *)
      Int32.of_int (audio_samples * 2 * 2);
    (* set the audio callback to get the next chunk of the audio buffer *)
    Sdl.as_callback = None; }
  in 
  let _ = 
    match Sdl.rw_from_file "a0.wav" "r" with
    | Error (_) -> print_endline "error reading file"
    | Ok rw_ops -> 
      match Sdl.load_wav_rw rw_ops wav_audio_spec Bigarray.int16_signed with
      | Error (_) -> let _ = Sdl.rw_close rw_ops in print_endline "error parsing wav file"
      | Ok (spec, bigarr) ->
        let _ = Sdl.rw_close rw_ops in 
        let _ = audiofile := Some bigarr in
        (* let _ = print_endline (string_of_int (spec.as_format)) in
        let _ = print_endline (string_of_int (Sdl.Audio.s32)) in *)
        print_endline (string_of_int (Bigarray.Array1.dim bigarr))
  in
  let desired_audiospec =
    { Sdl.as_freq = audio_freq;
      as_format = Sdl.Audio.s32;
      Sdl.as_channels = 2;
      Sdl.as_samples = audio_samples;
      Sdl.as_silence = 0;
      Sdl.as_size =
        Int32.of_int (audio_samples * 4 * 2);
      (* set the audio callback to get the next chunk of the audio buffer *)
      Sdl.as_callback = !audio_callback; }
  in
  match Sdl.open_audio_device None false desired_audiospec 0 with
  | Error _ -> Sdl.log "Can't open audio device"; exit 1
  | Ok (device_id, _) -> device_id

let video_setup font =
  match Sdl.create_window_and_renderer ~w:640 ~h:480 Sdl.Window.opengl with
  | Error ( `Msg e ) -> Sdl.log "Create window error: %s" e; exit 1
  | Ok (w,r) -> 
    (* clear the buffer *)
    let _ = Sdl.render_clear r in
    (* set the color to yellow *)
    let _ = Sdl.set_render_draw_color r 255 255 0 255 in
    (* draw lines *)
    let _ = Sdl.render_draw_line r 50 50 100 100 in
    let _ = Sdl.render_draw_line r 150 50 100 100 in
    let rect = Sdl.Rect.create 200 200 100 100 in
    let _ = Sdl.render_fill_rect r (Some rect) in

    (* text stuff *)
    let fg_color = Sdl.Color.create 255 255 255 255 in
    (* defines the bounds of the font *)
    Ttf.size_utf8 font "foobar" >>= fun (text_w, text_h) ->
    let text_rect = Sdl.Rect.create 100 100 text_w text_h in
    Ttf.render_text_solid font "foobar" fg_color >>= fun (sface) ->
    Sdl.create_texture_from_surface r sface >>= fun (font_texture) ->
    let _ = Sdl.render_copy ~dst:text_rect r font_texture in
    
    (* flush the buffer *)
    let _ = Sdl.render_present r in
    w

let main () = match Sdl.init Sdl.Init.(audio + video) with
| Error ( `Msg e ) -> Sdl.log "Init error: %s" e; exit 1
| Ok () ->
    (* init ttf *)
    Ttf.init () >>= fun () ->
    Ttf.open_font "agane.ttf" 72 >>= fun (font) ->
      let window = video_setup font in
      let device_id = audio_setup () in
      Gc.full_major ();
      let () = Sdl.pause_audio_device device_id false in
      let e = Sdl.Event.create () in
      let rec loop () = match Sdl.wait_event (Some e) with
      | Error ( `Msg err ) -> Sdl.log "Could not wait event: %s" err; ()
      | Ok () ->
          match Sdl.Event.(enum (get e typ)) with
          | `Quit ->
              let _ = print_endline "safely exiting and cleaning up" in
              Sdl.pause_audio_device device_id true;
              Sdl.close_audio_device device_id;
              Sdl.destroy_window window;
              Sdl.quit()
          | `Key_down -> print_endline (Sdl.get_key_name (Sdl.Event.(get e keyboard_keycode))); loop ()
          | `Key_up -> print_endline (Sdl.get_key_name (Sdl.Event.(get e keyboard_keycode))); loop ()
          | `Mouse_button_down -> print_endline (string_of_int (Sdl.Event.(get e mouse_button_x))^","^(string_of_int(Sdl.Event.(get e mouse_button_y)))); loop()
          | `Mouse_button_up -> print_endline (string_of_int (Sdl.Event.(get e mouse_button_x))^","^(string_of_int(Sdl.Event.(get e mouse_button_y)))); loop()
          | _ -> loop ()
      in
      loop ()

let () = main ()
