open Yojson.Basic.Util

type timed_soundpack = {
  soundpack: int;
  beat: float;
  length: float;
}
type timed_note = {
  row: int;
  col: int;
  beat: float;
  length: float;
}
type midi_data =
  | Soundpack of timed_soundpack
  | Note of timed_note

type midi = {
  name: string;
  notes: midi_data list;
  current_beat: float ref;
}

let parse_data data =
  let json = to_assoc data in
  let note = List.assoc "note" json |> to_int in
  let beat = List.assoc "beat" json |> to_number in
  let length = List.assoc "length" json |> to_number in
  if note >= 47 && note <= 50 then
    Soundpack {soundpack = note - 47; beat = beat; length = length}
  else
    Note {row = note / 12; col = note mod 12; beat = beat; length = length}

let parse_midi filename =
  let json = Yojson.Basic.from_file filename |> to_assoc in
  let name = List.assoc "name" json |> to_string in
  let data = List.assoc "song_data" json |> to_list in
  let notes = List.map parse_data data in
  {name = name; notes = notes; current_beat = ref 0.0}
