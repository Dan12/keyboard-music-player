(* These states are the various states a key can be in *)
type key_state =
  | KSDown
  | KSUp

type keyboard = key_state array array

let create_keyboard (rows, cols) =
  Array.make_matrix rows cols KSUp

let process_event ipt keyboard =
  match ipt with
  | Keyboard_layout.KOKeydown (r,c) ->
    begin
      match keyboard.(r).(c) with
      | KSUp ->
        keyboard.(r).(c) <- KSDown;
        true
      | _ -> false
    end
  | Keyboard_layout.KOKeyup (r,c) ->
    begin
      match keyboard.(r).(c) with
      | KSDown ->
        keyboard.(r).(c) <- KSUp;
        true
      | _ -> false
    end
  | _ -> false

let get_state (r,c) keyboard =
  keyboard.(r).(c)