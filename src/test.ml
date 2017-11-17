open OUnit2

let layout_tests = 
  let open Keyboard_layout in
  let layout = parse_layout "standard_keyboard_layout.json" in
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

let tests = layout_tests @ state_tests

let _ = run_test_tt_main ("suite" >::: tests)