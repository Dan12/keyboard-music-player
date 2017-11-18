open Yojson.Basic.Util

type keyboard_mapping = RowCol of int*int | Soundpack of int

type keyboard_layout = (int, keyboard_mapping) Hashtbl.t

type keyboard_output =
  | KOKeydown of int*int
  | KOKeyup of int*int
  | KOSoundpackSet of int
  | KOUnmapped

type keyboard_input =
  | KIKeydown of int
  | KIKeyup of int

let parse_arrows map lst =
  let add_to_map i num =
    Hashtbl.add map (num |> to_int) (Soundpack i)
  in List.iteri add_to_map lst

let parse_keyboard map lst =
  let add_col r i num =
    Hashtbl.add map (num |> to_int) (RowCol (r,i))
  in
  let add_row i r =
    List.iteri (add_col i) (r |> to_list)
  in
  List.iteri add_row lst


let parse_layout filename =
  let json = to_assoc (Yojson.Basic.from_file filename) in
  let keyboard_array = List.assoc "keyboard" json |> to_list in
  let switch_soundpack = List.assoc "arrows" json |> to_list in
  let map = Hashtbl.create 64 in
  parse_keyboard map keyboard_array;
  parse_arrows map switch_soundpack;
  map

let to_upper keycode =
  let a = 97 in
  let z = 122 in
  if keycode >= a && keycode <= z
  then keycode - 32
  else keycode

let process_key ipt layout =
  match ipt with
  | KIKeydown keycode ->
    begin
      let keycode = to_upper keycode in
      match Hashtbl.find_opt layout keycode with
      | Some RowCol (r,c) -> KOKeydown (r,c)
      | Some Soundpack s -> KOSoundpackSet s
      | None -> KOUnmapped
    end
  | KIKeyup keycode ->
    begin
      let keycode = to_upper keycode in
      match Hashtbl.find_opt layout keycode with
      | Some RowCol (r,c) -> KOKeyup (r,c)
      | _ -> KOUnmapped
    end
