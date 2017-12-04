type adsr_t = int*int*float*int

type adsr_state = {
  mutable state: int;
  mutable sample_pos: int;
}

(* converts samples to seconds *)
let samples_of_seconds sr t =
  int_of_float (float sr *. t)

let make sr (a,d,s,r) =
  samples_of_seconds sr a,
  samples_of_seconds sr d,
  s,
  samples_of_seconds sr r

let init_state () =
  {
    state = 0;
    sample_pos = 0;
  }

let release_state state =
  state.state <- 3;
  state.sample_pos <- 0

let is_dead state =
  state.state = 4

let process_sample adsr state (sample_l, sample_r) =
  let (a,d,s,r) = adsr in
  match state.state with
  | 0 ->
    (* calculate the gain scalar in attack phase *)
    let scalar = (float_of_int state.sample_pos) /. (float_of_int a) in
    (* increment the sample position *)
    state.sample_pos <- state.sample_pos+1;
    (* set to the next state if at that position *)
    if state.sample_pos >= a then
      state.state <- 1;
      state.sample_pos <- 0;
    (* return the scaled samples *)
    (sample_l *. scalar, sample_r *. scalar)
  | 1 ->
    (* calculate the gain scalar in decay phase *)
    let scalar = 1. +. ((0.8 -. 1.) *. (float_of_int state.sample_pos)) /. (float_of_int d) in
    (* increment the sample position *)
    state.sample_pos <- state.sample_pos+1;
    (* set to the next state if at that position *)
    if state.sample_pos >= d then
      state.state <- 2;
      state.sample_pos <- 0;
    (* return the scaled samples *)
    (sample_l *. scalar, sample_r *. scalar)
  | 2 ->
    (sample_l *. s, sample_r *. s)
  | 3 -> 
    (* calculate the gain scalar in release phase *)
    let scalar = (float_of_int state.sample_pos) /. (float_of_int a) in
    (* increment the sample position *)
    state.sample_pos <- state.sample_pos+1;
    (* set to the next state if at that position *)
    if state.sample_pos >= r then
      state.state <- 4;
      state.sample_pos <- 0;
    (* return the scaled samples *)
    (sample_l *. scalar, sample_r *. scalar)
  | _ -> (0.,0.)