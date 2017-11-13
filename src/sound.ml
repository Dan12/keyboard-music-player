open Bigarray
open Tsdl

type sound = {
  pitches: (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray list;
  looping: bool;
  hold_to_play: bool;
  groups: int list;
  quantization: int;
  mutable playing: bool;
  mutable pitch_index: int;
  mutable current_pitch: (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray;
  mutable current_pitch_len: int;
  mutable buffer_index: int;
}

(* The options for a sound *)
type sound_options = {
  loop: bool;
  hold_to_play: bool;
  groups: int list;
  quantization: int; 
}

let create files options = 
  let load_next_pitch file lst =
    match Tsdl_wrapper.load_wav file with
    | None ->  failwith ("Unable to load "^file)
    | Some arr -> arr::lst
  in 
  let pitches = List.fold_right load_next_pitch files [] in
  if List.length pitches = 0 then
    failwith "Pitches length must be greater than 0"
  else
  let current_pitch = List.hd pitches in
  let current_pitch_len = Array1.dim current_pitch in
  {
    pitches = pitches;
    looping = options.loop;
    hold_to_play = options.hold_to_play;
    groups = options.groups;
    quantization = options.quantization;
    playing = false;
    pitch_index = 0;
    current_pitch = current_pitch;
    current_pitch_len = current_pitch_len;
    buffer_index = 0;
  }

let play_sound sound =
  sound.playing <- true

let pause_sound sound =
  sound.playing <- false

let stop_sound sound =
  sound.playing <- false;
  sound.buffer_index <- 0

let next_pitch sound = 
  let next_index =
    if sound.pitch_index == List.length sound.pitches then
      0
    else
      sound.pitch_index + 1
  in sound.pitch_index <- next_index;
  sound.current_pitch <- List.nth sound.pitches sound.pitch_index;
  sound.current_pitch_len <- Array1.dim sound.current_pitch

let get_next_values sound =
  if sound.playing then
    if sound.buffer_index + 1 >= sound.current_pitch_len then
      let _ = sound.playing <- false in
      (0,0)
    else
      let l = sound.current_pitch.{sound.buffer_index} in
      let r = sound.current_pitch.{sound.buffer_index+1} in
      let _ = sound.buffer_index <- sound.buffer_index + 2 in
      (l,r)
  else
    (0,0)

let is_playing sound = sound.playing