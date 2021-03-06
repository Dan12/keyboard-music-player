open Tsdl
open Result
open Tsdl_ttf
open Bigarray

(* the tsdl state is the state of the wrapper *)
type tsdl_state = {
  window: Tsdl.Sdl.window;
  renderer: Tsdl.Sdl.renderer;
  audio_device: Tsdl.Sdl.audio_device_id;
  draw_callback: (Tsdl.Sdl.renderer -> unit) option ref;
  audio_callback: ((int32, int32_elt, c_layout) Array1.t -> unit) option ref;
  event_callback: (Tsdl.Sdl.event -> unit) option ref;
  tick_callback: (unit -> unit) option ref;
}

(* [tsdl_state_singleton] is the singleton instance of teh tsdl_state
 * There is only 1 tsdl state, because once the main loop is started
 * you can only exit by quitting
 *)
let tsdl_state_singleton = ref None

(* [o >>= f] is the Result/error handling bind infix function
 * that executes [f x] if [o] is [`Ok x].
 * Otherwise, prints the error message.
 *)
let (>>=) o f =
  match o with
  | Error (`Msg e) ->
    failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

(* [test_state f] Tsld state bind function that only
 * executes [f state] if [state] is not None
 *)
let test_state f =
  match !tsdl_state_singleton with
  | None -> ()
  | Some s -> f s

(* This mutex will lock on the audio callback and the event callback
 * all mutually exclusive actions should be done in one or the other.
 * Note that the tick callback and draw callback are not mutually exclusive
 * to the audio lock.
 *)
let audio_mutex = Mutex.create ()

(* [audio_callback output] wrapper for the audio callback in the state *)
let audio_callback output =
  Mutex.lock audio_mutex;

  test_state (fun s ->
  match !(s.audio_callback) with
  | None ->
    Array1.fill output (Int32.of_int 0)
  | Some c ->
    c output);

  Mutex.unlock audio_mutex

(* [audio_callback_ref] Keeps a ref to the audio callback so that it 
 * doesn't get garbage collected *)
let audio_callback_ref =
  ref (Some (Sdl.audio_callback int32 audio_callback))

(* samples per second *)
let audio_freq = 44100
(* If set below 1024, there seems to be a race condition
 * and close deadlocks inside of quit *)
let audio_samples = 1024

(* [audio_setup] initializes the audio callback and returns a device id to
 * identify the audio device created during initialization
 *)
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

(* [video_setup] sets up the rendered with the given window size
 * and returns an instance of the initalized window and renderer
 *)
let video_setup (w,h) =
  Sdl.create_window_and_renderer
    ~w:w
    ~h:h
    Sdl.Window.windowed
  >>= fun window_renderer ->
  window_renderer

let init window_dims =
  match !tsdl_state_singleton with
  | Some _ -> ()
  | None ->
    Sdl.init Sdl.Init.(audio + video) >>= fun () ->
    Ttf.init () >>= fun () ->
    let (window, renderer) = video_setup window_dims in
    let _ = Tsdl.Sdl.set_render_draw_blend_mode renderer Tsdl.Sdl.Blend.mode_blend in
    let device_id = audio_setup () in
    tsdl_state_singleton := Some {
      window = window;
      renderer = renderer;
      audio_device = device_id;
      draw_callback = ref None;
      audio_callback = ref None;
      event_callback = ref None;
      tick_callback = ref None;
    }

(* [quit] will clean up and close the Sdl context. Has no effect if called
 * before init.
 *)
let quit () =
  test_state (fun s ->
    print_endline "Safely exiting and cleaning up";
    Sdl.destroy_window s.window;
    (* This deadlocks, so just crash *)
    (* Mutex.lock audio_mutex;
    Sdl.pause_audio_device s.audio_device true;
    Sdl.close_audio_device s.audio_device;
    Sdl.quit();
    Mutex.unlock audio_mutex; *))

let set_draw_callback func =
  test_state (fun s ->
  s.draw_callback := Some func)

let set_event_callback func =
  test_state (fun s ->
  s.event_callback := Some func)

let set_audio_callback func =
  test_state (fun s ->
  s.audio_callback := Some func)

let set_tick_callback func =
  test_state (fun s ->
  s.tick_callback := Some func)

let prev_refresh_time = ref 0.
let refresh_wait_ms = 40.
let start_main_loop () =
  test_state (fun s ->
  (* IDK why this is necessary *)
  Gc.full_major ();

  (* start the audio callback *)
  let () = Sdl.pause_audio_device s.audio_device false in

  (* create the event *)
  let e = Sdl.Event.create () in

  (* create a running boolean to exit out of the loop when necessary *)
  let running = ref true in
  while !running do
    (* always delay 1ms, used for ticks *)
    Sdl.delay (Int32.of_int 1);

    (match !(s.tick_callback) with
    | None -> ()
    | Some tick_callback -> tick_callback ());

    (* refresh at constant rate *)
    let cur_time = Unix.gettimeofday () in

    let time_taken = (cur_time -. !prev_refresh_time) *. 1000. in
    if time_taken >= refresh_wait_ms then
      begin
        (* set prev refresh time to the cur time minus the time overshot *)
        let time_wasted_ms = min refresh_wait_ms ((time_taken -. refresh_wait_ms)) in
        prev_refresh_time := cur_time -. (time_wasted_ms /. 1000.);
        (* call the draw callback if it exists *)
        match !(s.draw_callback) with
        | None -> ()
        | Some draw_callback ->
          draw_callback s.renderer;
      end
    else
      ();

    (* get all of the events that happend while we were waiting *)
    while !running && Sdl.poll_event (Some e) do
          match Sdl.Event.(enum (get e typ)) with
          | `Quit ->
              (* handle quit event internally *)
              quit ();
              running := false;
          | _ ->
            (* handle all other events through callback if it exists *)
            (match !(s.event_callback) with
            | None -> ()
            | Some event_callback ->
              Mutex.lock audio_mutex;
              event_callback e;
              Mutex.unlock audio_mutex)
    done
  done)

(* The spec to use when loading a wav file.
 * 16 bit saves disk space and is the default export format of ffmpeg.
 *)
let wav_audio_spec =
  {
    Sdl.as_freq = audio_freq;
    as_format = Sdl.Audio.s16;
    Sdl.as_channels = 2;
    Sdl.as_samples = audio_samples;
    Sdl.as_silence = 0;
    Sdl.as_size =
      (* size of buffer in bytes (samples*channels*bytes per int) *)
      Int32.of_int (audio_samples * 2 * 2);
    (* set the audio callback to get the next chunk of the audio buffer *)
    Sdl.as_callback = None;
  }
  
let load_wav filename =
  match Sdl.rw_from_file filename "r" with
  | Error (_) ->
    print_endline "error reading file";
    None
  | Ok rw_ops ->
    match Sdl.load_wav_rw rw_ops wav_audio_spec int16_signed with
    | Error (_) ->
      let _ = Sdl.rw_close rw_ops in
      print_endline "error parsing wav file";
      None
    | Ok (spec, audio_arr) ->
      let _ = Sdl.rw_close rw_ops in
      Some audio_arr
