open Keyboard
open Keyboard_layout
open Song
(* This module implements the singleton model by accessing all of our data
   from here. *)

type state = SKeyboard | SFileChooser | SSynthesizer

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
val get_midi_buttons : unit -> Button_standard.button list

(* [get_file_buttons] returns the file buttons. *)
val get_file_buttons : unit -> Button_standard.button list

(* [get_file_location] returns the path to all the song/midi files. *)
val get_file_location : unit -> string

val set_selected_filename : string -> unit

(* [set_filename_buttons dir] stores all the song/midi files. *)
val set_filename_buttons : string -> unit

(* [get_filename_buttons] returns all the song/midi files. *)
val get_filename_buttons : unit -> Button_standard.button list

(* [get_num_filename_buttons] returns the number of filenames. *)
(* val get_num_filename_buttons : unit -> int *)

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

(* [set_bpm_pos p] sets the position of the bpm slider to [p]. *)
val set_bpm_pos : float -> unit

(* [get_bpm_pos] returns the current position of the bpm slider. *)
val get_bpm_pos : unit -> float

(* [set_bpm_scrubbing b] changes [b]. *)
val set_bpm_scrubbing : bool -> unit

(* [is_bpm_scrubbing] returns [bpm_scrubbing]. *)
val is_bpm_scrubbing : unit -> bool

(* [get_bpm_pos_min] returns [bpm_pos_min]. *)
val get_bpm_pos_min : unit -> float

(* [get_bpm_pos_max] returns [bpm_pos_max]. *)
val get_bpm_pos_max : unit -> float

(* [set_midi_load load] sets the value of [should_load_midi]*)
val set_midi_load : bool -> unit

(* [set_scrubbing scrubbing] changes [scrubbing]. *)
val set_scrubbing : bool -> unit

(* [is_scrubbing] returns [scrubbing]. *)
val is_scrubbing : unit -> bool

(* [get_scrub_button_pos] returns the current [scrub_button_pos]. *)
val get_scrub_pos : unit -> float

(* [set_scrub_pos pos] sets [scrub_pos].
   Range of [pos] is from [get_scrub_pos_min] to [get_scrub_max_pos]. *)
val set_scrub_pos : float -> unit

(* [get_scrub_pos_min] returns the minimum possible position for
   [scrub_pos]. *)
val get_scrub_pos_min : unit -> float

(* [get_scrub_pos_max] returns the maximum possible position for
   [scrub_pos]. *)
val get_scrub_pos_max : unit -> float

(* [get_beats] returns the number of beats in the current midi file. *)
val get_beats : unit -> float

(* [set_beats beats] saves the number of beats in the current midi file.  *)
val set_beats : float -> unit

(* [set_buffer audio_output] compute the fft of [audio_output] and cache
 * it in the model
 *)
val set_buffer : (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit

(* [get_buffer] get the most recent fft *)
val get_buffer : unit -> Complex.t array

val get_adsr_params : unit -> float*float*float*float

val set_adsr_params : float*float*float*float -> unit

val get_filter : unit -> Filter.filter_t

val set_filter_params : Filter.filter_kind*float*float -> unit