open Bigarray

type sound_manager = {
  mutable sounds_playing: Sound.sound list;
}
(* TODO needs samples played counter *)

let sound_manager_singleton = ref None

let init () =
  match !sound_manager_singleton with
  | Some _ -> ()
  | None ->
    sound_manager_singleton := Some {
      sounds_playing = [];
    }

let test_manager f =
  match !sound_manager_singleton with
  | None -> ()
  | Some s -> f s

let key_pressed row_col =
  test_manager 
  begin
  fun (s) ->
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
        let new_sounds = List.filter is_in_groups s.sounds_playing in
        (* add the new sound to the group *)
        if List.mem sound new_sounds then
          ()
        else
          s.sounds_playing <- sound::new_sounds
  end

let key_released row_col =
  test_manager
  begin
  fun (s) ->
    let song = Model.get_song () in
      match Song.get_sound row_col song with
      | None -> ()
      | Some sound ->
        if Sound.is_hold_to_play sound then
          begin
            Sound.stop_sound sound;
            let removed_list = List.filter (fun ts -> ts <> sound) s.sounds_playing in
            s.sounds_playing <- removed_list
          end
        else
          (* TODO if looping and not hold to play, then stop  *)
          ()
  end

let add_sound (cur_l, cur_r) sound =
  let (sample_l, sample_r) = Sound.get_next_values sound in
  (cur_l+sample_l, cur_r+sample_r)

let audio_callback output =
  match !sound_manager_singleton with
  | None -> Array1.fill output (Int32.of_int 0)
  | Some s ->
    match List.nth_opt s.sounds_playing 0 with
    | None -> Array1.fill output (Int32.of_int 0)
    | Some _ ->
      begin
        let arr_len = ((Array1.dim output / 2) - 1) in
        for i = 0 to arr_len do
          let (sample_l, sample_r) = List.fold_left add_sound (0,0) s.sounds_playing in
          if sample_l > 65536 then
            print_endline "to 0"
          else
            ();
          output.{2*i} <- Int32.of_int (sample_l lsl 15);
          output.{2*i + 1} <- Int32.of_int (sample_r lsl 15);
        done;
        (* Remove all sounds not being played anymore *)
        let filtered_sounds = List.filter Sound.is_playing s.sounds_playing in
        s.sounds_playing <- filtered_sounds
      end
