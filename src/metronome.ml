(* TODO add comments for non mli variables *)

let start_time = ref (Unix.gettimeofday())
let last_time = ref (Unix.gettimeofday())
let cached_beat = ref 0.0
let bpm = ref 0
let min_bpm = 50.0
let max_bpm = 300.0

let prev_minutes_elapsed = ref 0.0
let current_minutes_elapsed = ref 0.0
let minutes_elapsed () =
  let temp = (!last_time -. !start_time) /. 60.0 in
  prev_minutes_elapsed := !current_minutes_elapsed;
  current_minutes_elapsed := temp

let recent = ref (Unix.gettimeofday())
let tick () =
  last_time := Unix.gettimeofday();
  cached_beat := !cached_beat +. (!bpm |> float_of_int) *. (minutes_elapsed(); !current_minutes_elapsed -. !prev_minutes_elapsed)

let set_bpm beat = bpm := beat

let set_bpm_by_percent percent =
  let bpm_diff = max_bpm -. min_bpm in
  bpm := (int_of_float ((percent *. bpm_diff) +. min_bpm))

let get_bpm () = !bpm

let get_percent () =
  (float_of_int !bpm) /. (max_bpm -. min_bpm)

let get_beat () = !cached_beat

let set_beat beat =
  cached_beat := beat;
  last_time := Unix.gettimeofday();
  start_time := !last_time -. beat /. (!bpm |> float_of_int) *. 60.0

let unpause () =
  let seconds = (minutes_elapsed(); !current_minutes_elapsed) *. 60.0 in
  start_time := (Unix.gettimeofday() -. seconds);
  tick()

let reset () =
  let time = Unix.gettimeofday() in
  start_time := time;
  last_time := time;
  prev_minutes_elapsed := 0.0;
  current_minutes_elapsed := 0.0;
  cached_beat := 0.0;
  bpm := 0
