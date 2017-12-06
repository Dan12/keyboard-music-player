open Bigarray

(* Only need to keep track of sounds  *)
type sound_manager = {
  mutable sounds_playing: Sound.sound list;
  mutable synth_sounds_playing: Synth.synth list;
}

(* [manager] is the singleton instance of the sound_manager *)
let manager = {
  sounds_playing = [];
  synth_sounds_playing = [];
}

let key_pressed row_col =
  match Model.get_state () with
  | Model.SSynthesizer ->
    begin
      match List.find_opt (Synth.is_equal row_col) manager.synth_sounds_playing with
      | Some s ->
        Synth.start s
      | None ->
        let new_sound = Synth.create Synth.Square row_col in
        manager.synth_sounds_playing <- new_sound::manager.synth_sounds_playing
    end
  | Model.SKeyboard ->
    begin
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
    end
  | Model.SFileChooser -> ()

let key_released row_col =
  match Model.get_state () with
  | Model.SSynthesizer ->
    begin
      let release s =
        if Synth.is_equal row_col s then
          Synth.release s in
      List.iter release manager.synth_sounds_playing
    end
  | Model.SKeyboard ->
    begin
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
    end
  | Model.SFileChooser -> ()

let add_sound (cur_l, cur_r) sound =
  let (sample_l, sample_r) = Sound.get_next_values sound in
  (cur_l+sample_l, cur_r+sample_r)

let add_custom_sound cur sound =
  let sample = Synth.get_next_sample sound in
  cur +. sample


let max_32 = 2147483647
let min_32 = -2147483648
let clip s =
  if s > max_32 then
    max_32
  else if s < min_32 then
    min_32
  else
    s

let audio_callback output =
  begin
    match Model.get_state () with
    | Model.SSynthesizer ->
      begin
        let arr_len = ((Array1.dim output / 2) - 1) in
        for i = 0 to arr_len do
          let sample = List.fold_left add_custom_sound 0. manager.synth_sounds_playing in
          let filter = Model.get_filter () in
          let filtered_sample = Filter.process filter sample in
          let sample_int = int_of_float (filtered_sample *. 2147483647.) in
          let sample_clipped = clip sample_int in
          output.{2*i} <- Int32.of_int (sample_clipped);
          output.{2*i + 1} <- Int32.of_int (sample_clipped);
        done;
        (* filter out the only the sounds being played *)
        manager.synth_sounds_playing <- List.filter Synth.is_playing manager.synth_sounds_playing
      end
    | Model.SKeyboard ->
      begin
        let arr_len = ((Array1.dim output / 2) - 1) in
        for i = 0 to arr_len do
          let (sample_l, sample_r) = List.fold_left add_sound (0,0) manager.sounds_playing in
          let sample_l = clip (sample_l lsl 15) in
          let sample_r = clip (sample_r lsl 15) in
          output.{2*i} <- Int32.of_int sample_l;
          output.{2*i + 1} <- Int32.of_int sample_r;
        done;
        (* Remove all sounds not being played anymore *)
        let filtered_sounds = List.filter Sound.is_playing manager.sounds_playing in
        manager.sounds_playing <- filtered_sounds;
      end
    | _ ->
      Array1.fill output (Int32.of_int 0)
  end;
  Model.set_buffer output
  
