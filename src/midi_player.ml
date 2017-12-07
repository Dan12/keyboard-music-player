open Midi

(* reference so that midi_players are only made once *)
let midi_singleton:(midi ref) = ref empty

let set_midi filename =
  midi_singleton := (parse_midi filename)

let get_midi () = !midi_singleton
