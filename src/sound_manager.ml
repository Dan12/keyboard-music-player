open Bigarray

(* Only need to keep track of sounds  *)
type sound_manager = {
  mutable sounds_playing: Sound.sound list;
}

let manager = {
  sounds_playing = [];
}

let key_pressed row_col =
  let song = Model.get_song () in
  match Song.get_sound row_col song with
  | None -> ()
  | Some sound ->
    (* stop and restart sound *)
    Sound.stop_sound sound;
    Sound.play_sound sound;

    (* stop all other sounds in this sounds group *)
    let sound_groups = Sound.get_groups sound in
    let is_in_groups test_sound =
      List.filter (Sound.in_group test_sound) sound_groups = []
    in
    let new_sounds = List.filter is_in_groups manager.sounds_playing in
    (* add the new sound to the group *)
    if List.mem sound new_sounds then
      ()
    else
    manager.sounds_playing <- sound::new_sounds

let key_released row_col =
  let song = Model.get_song () in
  match Song.get_sound row_col song with
  | None -> ()
  | Some sound ->
    if Sound.is_hold_to_play sound then
      begin
        Sound.stop_sound sound;
        let removed_list = List.filter (fun ts -> ts <> sound) manager.sounds_playing in
        manager.sounds_playing <- removed_list
      end
    else
      (* TODO if looping and not hold to play, then stop  *)
      ()

let add_sound (cur_l, cur_r) sound =
  let (sample_l, sample_r) = Sound.get_next_values sound in
  (cur_l+sample_l, cur_r+sample_r)

let audio_callback output =
  let arr_len = ((Array1.dim output / 2) - 1) in
  for i = 0 to arr_len do
    let (sample_l, sample_r) = List.fold_left add_sound (0,0) manager.sounds_playing in
    output.{2*i} <- Int32.of_int (sample_l lsl 15);
    output.{2*i + 1} <- Int32.of_int (sample_r lsl 15);
  done;
  (* Remove all sounds not being played anymore *)
  let filtered_sounds = List.filter Sound.is_playing manager.sounds_playing in
  manager.sounds_playing <- filtered_sounds;
  Model.set_buffer output
