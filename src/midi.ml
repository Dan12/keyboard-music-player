(* TODO add comments for non mli functions *)

open Yojson.Basic.Util
open Input_event_manager

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
  length: float;
  mutable notes: midi_data list;
  mutable played_notes: midi_data list;
}

let empty = {name=""; length=0.0; notes=[]; played_notes=[]}

let note_end_time = function
  | Soundpack s -> s.beat +. s.length
  | Note n -> n.beat +. n.length

let length_of_notes (notes:midi_data list) =
  List.fold_left (fun longest_end_time note ->
      let note_length = note_end_time note in
      if longest_end_time > note_length then
        longest_end_time
      else
        note_length) 0.0 notes

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
  let length = length_of_notes notes in
  {name = name; notes = notes; length = length; played_notes = []}

(* [set_key_downs notes beat] will artificially send key down events for the
 * notes whose beat has passed. Assumes notes is in ascending order of beat.
 * Returns (new_notes, new_played_notes).
 * [new_notes] = the remaining unplayed notes in midi, still in order.
 * [new_played_notes] = the notes that have just been played.
 *)
let rec set_key_downs notes beat =
  match notes with
  | [] -> ([], [])
  | h::t ->
    match h with
    | Soundpack s ->
      let play = s.beat <= beat in
      if play then
        (handle_keyboard_output (Keyboard_layout.KOSoundpackSet s.soundpack));
      set_note play h t beat
    | Note n ->
      let play = n.beat <= beat in
      if play then
        (handle_keyboard_output (Keyboard_layout.KOKeydown (n.row, n.col)));
      set_note play h t beat

and set_note play note remaining beat =
  if play then
    let (child_notes, child_played_notes) = set_key_downs remaining beat in
    (child_notes, note::child_played_notes)
  else
    (note::remaining, [])

let rec set_key_ups played_notes beat =
  match played_notes with
  | [] -> []
  | h::t ->
    match h with
    (* soundpacks don't do anything "on release" *)
    | Soundpack s -> set_key_ups t beat
    | Note n ->
      let end_time = n.beat +. n.length in
      if end_time <= beat then
        (handle_keyboard_output (Keyboard_layout.KOKeyup (n.row, n.col));
        set_key_ups t beat)
      else
        h::(set_key_ups t beat)

let tick midi beat =
  let (new_notes, new_played_notes) = set_key_downs midi.notes beat in
  let remaining_played_notes = set_key_ups midi.played_notes beat in
  midi.notes <- new_notes;
  midi.played_notes <- List.rev_append new_played_notes remaining_played_notes

let is_done midi =
  (List.length midi.notes) = 0

let length midi =
  midi.length
