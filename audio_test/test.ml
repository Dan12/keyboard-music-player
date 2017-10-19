(* Sample code provided by @psqu in issue #13. *)

open Tsdl
open Result

let audio_freq    = 44100
let audio_samples = 4096
let time = ref 0

let audio_callback output =
  (* output is 2*audio samples *)
  let open Bigarray in
  (* generate the next audio sample *)
  (* output dim is 2*4096 *)
  for i = 0 to ((Array1.dim output / 2) - 1) do
    let phase = ((float_of_int !time) /.
                 (66100.0 +.
                  1000.0 *. sin (0.0001 *. (float_of_int !time)))) *. 3000.0
    in
    let _ = (float_of_int !time) *. 0.03 in
    (* 1073741823 = 2^30, amplitude, volume = 1.0 is 50% max volume *)
    let volume = 1. in
    let sample = Int32.of_float ((sin phase) *. 1073741823.0 *. volume) in
    begin
      (* 2 channel audio, channels go next to each other *)
      output.{ 2 * i     } <- sample;
      output.{ 2 * i + 1 } <- sample;
      time := !time + 1
    end
  done

let audio_callback =
  ref (Some (Sdl.audio_callback Bigarray.int32 audio_callback))

let audio_setup () =
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

let video_setup () =
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
    (* flush the buffer *)
    let _ = Sdl.render_present r in
    w

let main () = match Sdl.init Sdl.Init.(audio + video) with
| Error ( `Msg e ) -> Sdl.log "Init error: %s" e; exit 1
| Ok () ->
    let window = video_setup () in
    let device_id = audio_setup () in
    Gc.full_major ();
    let () = Sdl.pause_audio_device device_id false in
    let e = Sdl.Event.create () in
    let rec loop () = match Sdl.wait_event (Some e) with
    | Error ( `Msg err ) -> Sdl.log "Could not wait event: %s" err; ()
    | Ok () ->
        match Sdl.Event.(enum (get e typ)) with
        | `Quit ->
            let _ = print_endline "safely exiting" in
            Sdl.pause_audio_device device_id true;
            Sdl.destroy_window window;
            Sdl.quit()
        | _ -> loop ()
    in
    loop ()

let () = main ()
