let start_time = ref (Unix.gettimeofday())
let last_time = ref (Unix.gettimeofday())
let cached_beat = ref 0.0
let bpm = ref 0

let minutes_elapsed () = (!last_time -. !start_time) /. 60.0

let tick () =
  last_time := Unix.gettimeofday();
  cached_beat := (!bpm |> float_of_int) *. minutes_elapsed()

let set_bpm beat = bpm := beat

let get_beat () = !cached_beat

let reset () = start_time := Unix.gettimeofday()
