(* This module will provide a type and a parser for a song. *)

(* The song type. TODO should this be abstract *)
type song

(* [parse_song_file filename] opens and parses the given file to
 * a song.
 *)
val parse_song_file : string -> song