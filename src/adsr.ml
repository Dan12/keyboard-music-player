(* code adapted from: https://github.com/savonet/ocaml-mm *)

type adsr_t = int*int*float*int

type adsr_state = {
  mutable state: int;
  mutable sample_pos: int;
  mutable prev_scalar: float;
}

(* converts samples to seconds *)
let samples_of_seconds sr t =
  int_of_float (float sr *. t)

let make_adsr sr (a,d,s,r) =
  samples_of_seconds sr a,
  samples_of_seconds sr d,
  s,
  samples_of_seconds sr r

let init_state () =
  {
    state = 0;
    sample_pos = 0;
    prev_scalar = 0.;
  }

let release_state state =
  state.state <- 3;
  state.sample_pos <- 0

let is_dead state =
  state.state = 4

let process_sample adsr state sample =
  let (a,d,s,r) = adsr in
  match state.state with
  | 0 ->
    if a <> 0 then
      begin
        (* calculate the gain scalar in attack phase *) 
        let scalar = (float_of_int state.sample_pos) /. (float_of_int a) in
        (* increment the sample position *)
        state.sample_pos <- state.sample_pos+1;
        state.prev_scalar <- scalar;
        (* set to the next state if at that position *)
        if state.sample_pos >= a then
          begin
            state.state <- 1;
            state.sample_pos <- 0;
          end;
        (* return the scaled samples *)
        sample *. scalar
      end
    else
      begin
        state.state <- 1;
        sample
      end
  | 1 ->
    if d <> 0 then
      begin
        (* calculate the gain scalar in decay phase *)
        let scalar = 1. +. ((s -. 1.) *. (float_of_int state.sample_pos)) /. (float_of_int d) in
        (* increment the sample position *)
        state.sample_pos <- state.sample_pos+1;
        state.prev_scalar <- scalar;
        (* set to the next state if at that position *)
        if state.sample_pos >= d then
          begin
            state.state <- 2;
            state.sample_pos <- 0;
          end;
        (* return the scaled samples *)
        sample *. scalar
      end
    else
      begin
        state.state <- 2;
        sample
      end
  | 2 ->
    state.prev_scalar <- s;
    sample *. s
  | 3 ->
    if r <> 0 then
      begin
        (* calculate the gain scalar in release phase *)
        let scalar = state.prev_scalar -. ((state.prev_scalar *. (float_of_int state.sample_pos)) /. (float_of_int r)) in
        (* increment the sample position *)
        state.sample_pos <- state.sample_pos+1;
        (* set to the next state if at that position *)
        if state.sample_pos >= r then
          begin
            state.state <- 4;
            state.sample_pos <- 0;
          end;
        (* return the scaled samples *)
        sample *. scalar
      end
    else
      begin
        state.state <- 4;
        sample
      end
  | _ -> 0.
