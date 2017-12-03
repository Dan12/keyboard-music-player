(* TODO add comments for non mli variables *)

open Midi

let midi_singleton:(midi ref) = ref empty
let isPlaying = ref false

let set_midi filename =
  midi_singleton := (parse_midi filename)

let get_midi () = !midi_singleton
