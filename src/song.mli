(* This module will provide a type and a parser for a song. *)

(* The song type. *)
type song

(* [parse_song_file filename] opens and parses the given file to
 * a song.
 *)
val parse_song_file : string -> song

(* [get_sound (row,col) song] returns the sound at the given [row] and
 * [col] for the [song]
 *)
val get_sound : int*int -> song -> Sound.sound option

(* [set_sound_pack pack_num song] sets [song]'s current soundpack
 * to [pack_num]. If [song] does not have a soundpack [pack_num],
 * then [song] goes to its default empty soundpack.
 *)
val set_sound_pack : int -> song -> unit

(* [get_sound_pack song] returns [song]'s current soundpack *)
val get_sound_pack : song -> int

(* [get_bpm song] returns the bpm of the given song *)
val get_bpm : song -> int
