open Keyboard
open Keyboard_layout
open Song
(* This module implements the singleton model by accessing all of our data
   from here. *)

type state = SKeyboard | SFileChooser

(* [get_width] returns the current window width. *)
val get_width : unit -> int

(* [get_height] returns the current window height. *)
val get_height : unit -> int

(* [set_keyboard k] sets the current state of the keyboard to [k]. *)
val set_keyboard : keyboard -> unit

(* [get_keyboard] returns the current keyboard state. *)
val get_keyboard : unit -> keyboard

(* [set_keyboard_layout kl] sets the keyboard_layout to be used to [kl]. *)
val set_keyboard_layout : keyboard_layout -> unit

(* [get_keyboard_layout] returns the keyboard_layout in use. *)
val get_keyboard_layout : unit -> keyboard_layout

(* [set_song s] sets the current song in use to [s]. *)
val set_song : song -> unit

(* [get_song] returns the current song in use. *)
val get_song : unit -> song

(* [set_state s] sets the current state to [s]. *)
val set_state : state -> unit

(* [get_state] returns the current state. *)
val get_state : unit -> state

(* [get_buttons] returns the buttons & their state. *)
val get_buttons : unit -> Button.buttons

(* [get_file_buttons] returns the file buttons. *)
val get_file_buttons : unit -> File_button.file_buttons

(* [get_file_location] returns the path to all the song/midi files. *)
val get_file_location : unit -> string

(* [set_filename_buttons d] stores all the song/midi files. *)
val set_filename_buttons : string -> unit

(* [get_filename_buttons] returns all the song/midi files. *)
val get_filename_buttons : unit -> File_button.filename_buttons

(* [get_num_filename_buttons] returns the number of filenames. *)
val get_num_filename_buttons : unit -> int

(* [set_midi_filename f] sets the current filename of the midi. *)
val set_midi_filename : string -> unit

(* [get_midi_filename] returns the filename of the midi. *)
val get_midi_filename : unit -> string

(* [start] sets [is_playing] = true and the initial values of [Metronome]. *)
val start_midi : unit -> unit

(* [pause] sets [is_playing] = false *)
val pause_midi : unit -> unit

(* [stop_midi] resets the metronome and sets [is_playing] = false. *)
val stop_midi : unit -> unit

(* [is_playing] returns whether or not the midi is playing. *)
val midi_is_playing : unit -> bool

(* [midi_should_load] returns true if the midi file should be reloaded *)
val midi_should_load : unit -> bool

(* [get_scrub_button_pos] returns the current [scrub_button_pos]. *)
val get_scrub_pos : unit -> int

(* [set_scrub_button_pos pos] sets [scrub_button_pos].
   Range of [pos] is from 0 to [get_scrub_button_max_pos]. *)
val set_scrub_pos : int -> unit

(* [get_scrub_button_max_pos] returns the maximum possible position for
   [scrub_button_pos]. *)
val get_scrub_max_pos : unit -> int

(* [set_buffer audio_output] compute the fft of [audio_output] and cache
 * it in the model
 *)
val set_buffer : (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit

(* [get_buffer] get the most recent fft *)
val get_buffer : unit -> Complex.t array
