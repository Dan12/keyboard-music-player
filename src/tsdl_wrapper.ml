open Tsdl
open Result
open Tsdl_ttf
open Bigarray

type tsdl_state = {
  window: Tsdl.Sdl.window;
  renderer: Tsdl.Sdl.renderer;
  audio_device: Tsdl.Sdl.audio_device_id;
  draw_callback: (Tsdl.Sdl.renderer -> unit) option ref;
  audio_callback: ((int32, int32_elt, c_layout) Bigarray.Array1.t -> unit) option ref;
  event_callback: (Tsdl.Sdl.event -> unit) option ref;
}

let tsdl_state_singleton = ref None

let (>>=) o f =
  match o with 
  | Error (`Msg e) -> 
    failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

let test_state f =
  match !tsdl_state_singleton with
  | None -> ()
  | Some s -> f s
  

let audio_mutex = Mutex.create ()

let audio_callback output =
  Mutex.lock audio_mutex;

  test_state (fun s ->
  match !(s.audio_callback) with
  | None -> ()
  | Some c ->
    c output);
    
  Mutex.unlock audio_mutex

let audio_callback_ref =
  ref (Some (Sdl.audio_callback Bigarray.int32 audio_callback))

let audio_freq = 44100
(* If set below 1024, there seems to be a race condition 
 * and close deadlocks inside of quit *)
let audio_samples = 1024
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
      Sdl.as_callback = !audio_callback_ref; }
  in
  Sdl.open_audio_device None false desired_audiospec 0 >>= fun (device_id, _) ->
  device_id

let video_setup () = 
  Sdl.create_window_and_renderer 
    ~w:640 
    ~h:480 
    Sdl.Window.windowed
  >>= fun window_renderer ->
  window_renderer

let init (w,h) = 
  match !tsdl_state_singleton with
  | Some _ -> ()
  | None ->
    Sdl.init Sdl.Init.(audio + video) >>= fun () ->
    Ttf.init () >>= fun () ->
    let (window, renderer) = video_setup () in
    let device_id = audio_setup () in

    (* IDK why this is necessary *)
    Gc.full_major ();

    tsdl_state_singleton := Some {
      window = window;
      renderer = renderer;
      audio_device = device_id;
      draw_callback = ref None;
      audio_callback = ref None;
      event_callback = ref None;
    }

let quit () = 
  test_state (fun s ->
    Sdl.pause_audio_device s.audio_device true;
    Sdl.close_audio_device s.audio_device;
    Sdl.destroy_window s.window;
    Sdl.quit())

let set_draw_callback func =
  test_state (fun s ->
  s.draw_callback := Some func)

let set_event_callback func =
  test_state (fun s ->
  s.event_callback := Some func)

let set_audio_callback func =
  test_state (fun s ->
  s.audio_callback := Some func)