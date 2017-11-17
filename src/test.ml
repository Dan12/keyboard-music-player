open OUnit2

let layout_tests = 
  let open Keyboard_layout in
  let layout = parse_layout "standard_keyboard_layout.json" in
  [
    "load test 1" >:: (fun _ -> assert_equal (KOKeydown (2,1)) (process_key (KIKeydown 83) layout));
    "load test 2" >:: (fun _ -> assert_equal (KOKeydown (3,10)) (process_key (KIKeydown 1073742053) layout));
    "load test 2" >:: (fun _ -> assert_equal (KOSoundpackSet 1) (process_key (KIKeydown 1073741906) layout));
  ]

let tests = layout_tests

let _ = run_test_tt_main ("suite" >::: tests)