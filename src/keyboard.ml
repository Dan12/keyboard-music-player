type key_visual =
  | String of string
  | Shift
  | Enter
  | Empty

type key_state =
  | KSDown
  | KSUp

(* These states are the various states a key can be in *)
type key = {mutable state:key_state; visual:key_visual}

type keyboard = key array array

let create_keyboard (rows, cols) =
  let init = {
    state = KSUp;
    visual = Empty;
  } in
  let arr = Array.make_matrix rows cols init in
  (* TODO load dynamically *)
  let strs = "1234567890-=qwertyuiop[]asdfghjkl;'_zxcvbnm,./__    " in
  for r = 0 to rows - 1 do
    for c = 0 to cols - 1 do
      let str = String.sub strs (r * cols + c) 1 in
      arr.(r).(c) <- {arr.(r).(c) with visual = String str};
    done;
  done;
  arr.(2).(11) <- {arr.(2).(11) with visual = Enter};
  arr.(3).(10) <- {arr.(3).(10) with visual = Shift};
  arr.(3).(11) <- {arr.(3).(11) with visual = Empty};
  arr

let process_event ipt keyboard =
  match ipt with
  | Keyboard_layout.KOKeydown (r,c) ->
    begin
      match keyboard.(r).(c).state with
      | KSUp ->
        keyboard.(r).(c).state <- KSDown;
        true
      | _ -> false
    end
  | Keyboard_layout.KOKeyup (r,c) ->
    begin
      match keyboard.(r).(c).state with
      | KSDown ->
        keyboard.(r).(c).state <- KSUp;
        true
      | _ -> false
    end
  | _ -> false

let get_state (r,c) keyboard =
  keyboard.(r).(c).state

let get_visual (r,c) keyboard =
  keyboard.(r).(c).visual
