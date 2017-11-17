open Yojson.Basic.Util

type sound_slot = Sound of Sound.sound | Empty

type song = {
  name: string;
  bpm: int;
  soundpacks: sound_slot array array array;
  mutable soundpack: int;
}

let parse_sound base s_json =
  let s = to_assoc s_json in
  if s = [] then
    Empty
  else
    let pitches_json = List.assoc "pitches" s |> to_list in
    let json_pitches_fullname p =
      p |> to_string |> Filename.concat base
    in
    let pitches = List.map json_pitches_fullname pitches_json in
    let hold_to_play = List.assoc "hold_to_play" s |> to_bool in
    let loop = List.assoc "loop" s |> to_bool in
    let groups_json = List.assoc "groups" s |> to_list in
    let groups = List.map to_int groups_json in
    let quantization = List.assoc "quantization" s |> to_int in
    let open Sound in
    let sound_options = {
      loop_option = loop;
      hold_to_play_option = hold_to_play;
      groups_option = groups;
      quantization_option = quantization;
    } in
    let sound = Sound.create pitches sound_options in
    Sound sound

let parse_sound_row base r_json =
  let r = to_list r_json in
  let row_list = List.map (parse_sound base) r in
  Array.of_list row_list  

let parse_soundpack base s_json =
  let s = to_list s_json in
  let soundpack = List.map (parse_sound_row base) s in
  Array.of_list soundpack

let parse_song_file file = 
  let base = Filename.dirname file in
  let json = to_assoc (Yojson.Basic.from_file file) in
  let name = List.assoc "name" json |> to_string in
  let bpm = List.assoc "bpm" json |> to_int in
  let sounds_json =  List.assoc "soundpacks" json |> to_list in
  let soundpack_list = List.map (parse_soundpack base) sounds_json in
  {
    name = name;
    bpm = bpm;
    soundpacks = Array.of_list soundpack_list;
    soundpack = 0;
  }

let get_sound (r,c) song =
  if song.soundpack = -1 then
    None
  else
    let soundpack = song.soundpacks.(song.soundpack) in
    if r >= Array.length soundpack then
      None
    else
      let row = soundpack.(r) in
      if c >= Array.length row then
        None
      else
        match row.(c) with
        | Sound s -> Some s
        | Empty -> None

let set_sound_pack s song =
  if s < 0 || s >= Array.length song.soundpacks then
    ()
  else
    song.soundpack <- s