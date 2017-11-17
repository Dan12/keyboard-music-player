open OUnit2

let keyboard_tests =
  let open Keyboard in
  let keyboard = create_keyboard (4,4) in
  [
    "keyboard test 1" >:: (fun _ -> assert_equal KSUp (get_state (1,1) keyboard));
    "keyboard test 1" >:: (fun _ -> assert_equal true (process_event (Keyboard_layout.KOKeydown (0,0)) keyboard));
    "keyboard test 1" >:: (fun _ -> assert_equal false (process_event (Keyboard_layout.KOKeyup (0,0)) keyboard));
    "keyboard test 1" >:: (fun _ -> assert_equal false (process_event (Keyboard_layout.KOUnmapped) keyboard));
    "keyboard test 1" >:: (fun _ -> assert_equal false (process_event (Keyboard_layout.KOSoundpackSet 1) keyboard));
  ]

let layout_tests = 
  let open Keyboard_layout in
  let layout = parse_layout "resources/standard_keyboard_layout.json" in
  [
    "load test 1" >:: (fun _ -> assert_equal (KOKeydown (2,1)) (process_key (KIKeydown 83) layout));
    "load test 2" >:: (fun _ -> assert_equal (KOKeydown (3,10)) (process_key (KIKeydown 1073742053) layout));
    "load test 2" >:: (fun _ -> assert_equal (KOSoundpackSet 1) (process_key (KIKeydown 1073741906) layout));
  ]

let state_tests =
  let _ =
    State_manager.set_state State_manager.SKeyboard;
  in
  let _ =
    let open State_manager in
    set_state SFileChooser;
  in
  let _ =
    State_manager.set_state State_manager.SKeyboard;
  in
  let open State_manager in
  [
    "state test 1" >:: (fun _ -> assert_equal SKeyboard (get_state ()));
  ]


let tests = layout_tests @ keyboard_tests @ state_tests

let _ = run_test_tt_main ("suite" >::: tests)