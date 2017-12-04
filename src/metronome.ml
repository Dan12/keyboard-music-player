(* TODO add comments for non mli variables *)

let start_time = ref (Unix.gettimeofday())
let last_time = ref (Unix.gettimeofday())
let cached_beat = ref 0.0
let bpm = ref 0

let minutes_elapsed () = (!last_time -. !start_time) /. 60.0

let tick () =
  last_time := Unix.gettimeofday();
  cached_beat := (!bpm |> float_of_int) *. minutes_elapsed()

let set_bpm beat = bpm := beat

let get_bpm () = !bpm

let get_beat () = !cached_beat

let set_beat beat =
  cached_beat := beat;
  last_time := Unix.gettimeofday();
  start_time := !last_time -. beat /. (!bpm |> float_of_int) *. 60.0

let unpause () =
  let seconds = minutes_elapsed() *. 60.0 in
  start_time := (Unix.gettimeofday() -. seconds);
  tick()

let reset () =
  let time = Unix.gettimeofday() in
  start_time := time;
  last_time := time;
  cached_beat := 0.0;
  bpm := 0
