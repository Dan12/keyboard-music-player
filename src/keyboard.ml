type key_state =
  | KSDown
  | KSUp

(* These states are the various states a key can be in *)

type arrows = {mutable left:key_state; mutable down:key_state;
               mutable up:key_state; mutable right:key_state}

type keyboard = key_state array array * arrows

let create_keyboard (rows, cols) =
  let arrows = {
    left = KSDown;
    up = KSUp;
    down = KSUp;
    right = KSUp;
  } in
  (Array.make_matrix rows cols KSUp, arrows)

let set_arrow arrows i =
  arrows.left <- if i = 0 then KSDown else KSUp;
  arrows.up <- if i = 1 then KSDown else KSUp;
  arrows.down <- if i = 2 then KSDown else KSUp;
  arrows.right <- if i = 3 then KSDown else KSUp

let process_event ipt (keyboard, arrows) =
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
  | Keyboard_layout.KOSoundpackSet i ->
    set_arrow arrows i;
    print_int i;
    false
  | _ -> false

let get_state_key (r,c) (keyboard, _) =
  keyboard.(r).(c)

let get_state_arrow i (_, arrows) =
  if i = 0
  then arrows.left
  else if i = 1
  then arrows.up
  else if i = 2
  then arrows.down
  else arrows.right
