(* [start_time] is the start time of the midi song to keep track of where
 * in the song is playing at a given time. *)
let start_time = ref (Unix.gettimeofday())
(* [last_time] is the most recent time set by tick() which tells the system
 * where in the song the system currently is in. *)
let last_time = ref (Unix.gettimeofday())
(* [cached_beat] is the current beat/location in the midi. *)
let cached_beat = ref 0.0
(* [bpm] is the bpm that the system is currently set to. *)
let bpm = ref 0
(* [min_bpm] is the set minimum bpm allowed. *)
let min_bpm = 50.0
(* [max_bpm] is the set maximum bpm allowed. *)
let max_bpm = 300.0

(* [prev_minutes_elapsed] represents the time elapsed before the tick. *)
let prev_minutes_elapsed = ref 0.0
(* [current_minutes_elapsed] represents the time elapsed after the tick. *)
let current_minutes_elapsed = ref 0.0
(* [minutes_elapsed] re-evaluates [prev_minutes_elapsed] and
 * [current_minutes_elapsed]. *)
let minutes_elapsed () =
  let temp = (!last_time -. !start_time) /. 60.0 in
  prev_minutes_elapsed := !current_minutes_elapsed;
  current_minutes_elapsed := temp

let tick () =
  last_time := Unix.gettimeofday();
  cached_beat := !cached_beat +. (!bpm |> float_of_int) *.
    (minutes_elapsed(); !current_minutes_elapsed -. !prev_minutes_elapsed)

let set_bpm beat = bpm := beat

let set_bpm_by_percent percent =
  let bpm_diff = max_bpm -. min_bpm in
  bpm := (int_of_float ((percent *. bpm_diff) +. min_bpm))

let get_bpm () = !bpm

let get_min_bpm () = min_bpm

let get_max_bpm () = max_bpm

let get_percent () =
  ((float_of_int !bpm) -. min_bpm) /. (max_bpm -. min_bpm)

let get_beat () = !cached_beat

let set_beat beat =
  cached_beat := beat;
  last_time := Unix.gettimeofday();
  start_time := !last_time -. beat /. (!bpm |> float_of_int) *. 60.0;
  let temp = (!last_time -. !start_time) /. 60.0 in
  prev_minutes_elapsed := temp;
  current_minutes_elapsed := temp

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
