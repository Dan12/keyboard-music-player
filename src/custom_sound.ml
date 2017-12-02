type waveform = Sine

type custom_sound = {
  waveform : waveform;
  freq : float;
  note_ocate : int*int;
  mutable sample : int;
}

let volume = 0.5
let sample_rate = 44100.
let pi = 3.14159265358979323846
let octave_shift = 2

let create w (octave, note) =
  let octave = octave + octave_shift in
  let n = note + 12 * (octave + 1) in
  let freq = 440. *. (2. ** ((float n -. 69.) /. 12.)) in
  {
    waveform = w;
    freq = freq;
    note_ocate = (note, octave);
    sample = 0;
  }  

let start s =
  s.sample <- 0

let get_next_sample s =
  match s.waveform with
  | Sine ->
    let theta = 2. *. pi *. s.freq /. sample_rate in
    let amp = volume *. sin(theta *. (float_of_int s.sample)) in
    let amp_int = int_of_float (amp *. 2147483648.) in
    s.sample <- s.sample + 1;
    (amp_int, amp_int)

let is_equal (o,n) s =
  let o = o + octave_shift in
  let (sn, so) = s.note_ocate in
  sn = n && so = o