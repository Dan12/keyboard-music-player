open Yojson.Basic.Util

type key_visual =
  | String of string
  | Shift
  | Enter
  | Empty

type keyboard_mapping = RowCol of int*int | Soundpack of int | Space

type keyboard_layout = ((int, keyboard_mapping) Hashtbl.t) * key_visual array array

type keyboard_output =
  | KOKeydown of int*int
  | KOKeyup of int*int
  | KOSoundpackSet of int
  | KOUnmapped
  | KOSpace

type keyboard_input =
  | KIKeydown of int
  | KIKeyup of int

(* [parse_arrows map arrows] add a soundpack keyboard mapping
 * to [map] for each arrow key in [arrows]
 *)
let parse_arrows map lst =
  let add_to_map i num =
    Hashtbl.add map (num |> to_int) (Soundpack i)
  in
  List.iteri add_to_map lst

(* [parse_arrows map keys] add a RowCol keyboard mapping
 * to [map] for each key in [keys]
 *)
let parse_keyboard map lst =
  let add_col r i num =
    Hashtbl.add map (num |> to_int) (RowCol (r,i))
  in
  let add_row i r =
    List.iteri (add_col i) (r |> to_list)
  in
  List.iteri add_row lst

(* [create_keyboard key_array dims] generate a 2D character map for [keys]
 * with the given [dims]
 *)
let create_keyboard keys (rows, cols) =
  let arr = Array.make_matrix rows cols Empty in
  let add_col r c str_json =
    let str = str_json |> to_string in
    let key =
      if String.equal str "SHIFT" then
        Shift
      else if String.equal str "ENTER" then
        Enter
      else if String.equal str "EMPTY" then
        Empty
      else
        String str
    in
    arr.(r).(c) <- key
  in
  let add_row i r =
    List.iteri (add_col i) (r |> to_list)
  in
  List.iteri add_row keys;
  arr

let parse_layout filename =
  let json = to_assoc (Yojson.Basic.from_file filename) in
  let keyboard_array = List.assoc "keyboard" json |> to_list in
  let switch_soundpack = List.assoc "arrows" json |> to_list in
  let key_array = List.assoc "keys" json |> to_list in
  let rows = List.assoc "rows" json |> to_int in
  let cols = List.assoc "cols" json |> to_int in
  let space = List.assoc "space" json |> to_int in
  let map = Hashtbl.create 64 in
  Hashtbl.add map space Space;
  parse_keyboard map keyboard_array;
  parse_arrows map switch_soundpack;
  let keys = create_keyboard key_array (rows, cols) in
    (map, keys)

(* [to_upper keycode] converts [keycode] to the ascii uppercase
 * representation of [keycode] if [keycode] represents a lowercase
 * ascii alphabet character
 *)
let to_upper keycode =
  let a = 97 in
  let z = 122 in
  if keycode >= a && keycode <= z then
    keycode - 32
  else
    keycode

let process_key ipt (layout, _) =
  match ipt with
  | KIKeydown keycode ->
    begin
      let keycode = to_upper keycode in
      match Hashtbl.find_opt layout keycode with
      | Some RowCol (r,c) -> KOKeydown (r,c)
      | Some Soundpack s -> KOSoundpackSet s
      | _ -> KOUnmapped
    end
  | KIKeyup keycode ->
    begin
      let keycode = to_upper keycode in
      match Hashtbl.find_opt layout keycode with
      | Some RowCol (r,c) -> KOKeyup (r,c)
      | Some Space -> KOSpace
      | _ -> KOUnmapped
    end


let get_visual (r,c) (_, keyboard) =
  keyboard.(r).(c)

let get_rows (_, keyboard) =
  Array.length keyboard

let get_cols (_, keyboard) =
  if Array.length keyboard == 0 then
    0
  else
    Array.length keyboard.(0)
