open Keyboard
open Keyboard_layout
open Song
(* This module implements the singleton model by accessing all of our data
   from here. *)

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
