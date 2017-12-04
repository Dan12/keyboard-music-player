(* code adapted from: https://github.com/savonet/ocaml-mm *)

type adsr_t = int*int*float*int

type adsr_state = {
  mutable state: int;
  mutable sample_pos: int;
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
    (* calculate the gain scalar in attack phase *)
    let scalar = (float_of_int state.sample_pos) /. (float_of_int a) in
    (* increment the sample position *)
    state.sample_pos <- state.sample_pos+1;
    (* set to the next state if at that position *)
    if state.sample_pos >= a then
      begin
        state.state <- 1;
        state.sample_pos <- 0;
      end;
    (* return the scaled samples *)
    sample *. scalar
  | 1 ->
    (* calculate the gain scalar in decay phase *)
    let scalar = 1. +. ((0.8 -. 1.) *. (float_of_int state.sample_pos)) /. (float_of_int d) in
    (* increment the sample position *)
    state.sample_pos <- state.sample_pos+1;
    (* set to the next state if at that position *)
    if state.sample_pos >= d then
      begin
        state.state <- 2;
        state.sample_pos <- 0;
      end;
    (* return the scaled samples *)
    sample *. scalar
  | 2 ->
    sample *. s
  | 3 -> 
    (* calculate the gain scalar in release phase *)
    let scalar = s -. (float_of_int state.sample_pos) /. (float_of_int r) in
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
  | _ -> 0.