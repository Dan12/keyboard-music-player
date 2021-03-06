(* code adapted from: https://github.com/savonet/ocaml-mm *)

type synth = {
  waveform : Model.waveform;
  freq : float;
  note_ocate : int*int;
  mutable sample : int;
  mutable playing : bool;
  adsr_config : Adsr.adsr_t;
  adsr_state: Adsr.adsr_state;
}

(* The base volume, makes it comparable with the level of the songs *)
let volume = 0.25
(* The sample rate of the audio system *)
let sample_rate = 44100.
let pi = 3.14159265358979323846
(* only get 4 octaves, so start at octave 3 *)
let octave_shift = 3

let create w (octave, note) =
  let octave = octave + octave_shift in
  let n = note + 12 * (octave + 1) in
  let freq = 440. *. (2. ** ((float n -. 69.) /. 12.)) in
  {
    waveform = w;
    freq = freq;
    note_ocate = (note, octave);
    sample = 0;
    playing = true;
    adsr_config = Adsr.make_adsr 44100 (Model.get_adsr_params ());
    adsr_state = Adsr.init_state ();
  }

let start s =
  s.sample <- 0

(** Fractional part of a float. *)
let fracf x =
  if x < 1. then
    x
  else if x < 2. then
    x -. 1.
  else
    fst (modf x)

let get_next_sample s =
  let t = (float_of_int s.sample) in
  let actual_freq = s.freq /. sample_rate in
  let amp =
    begin
      match s.waveform with
      | Model.Sine ->
        let theta = 2. *. pi *. actual_freq in
        sin(theta *. t)
      | Model.Square ->
        let theta = fracf (t *. actual_freq) in
        if theta < 0.5 then 1. else -1.
      | Model.Saw ->
        let x = fracf (t *. actual_freq) in
        2. *. x -. 1.
      | Model.Triangle ->
        let x = fracf (t *. actual_freq) +. 0.25 in
        if x < 0.5 then
          4. *. x -. 1.
        else
          4. *. (1. -. x) -. 1.
    end
  in
  let adsr_ctrl = Adsr.process_sample s.adsr_config s.adsr_state amp in
  let vol_ctrl = adsr_ctrl *. volume in
  s.sample <- s.sample + 1;
  vol_ctrl

let is_equal (o,n) s =
  let o = o + octave_shift in
  let (sn, so) = s.note_ocate in
  sn = n && so = o

let is_playing sound =
  not (Adsr.is_dead sound.adsr_state)

let release sound =
  Adsr.release_state sound.adsr_state
