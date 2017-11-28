let () =
  GMain.init ();
  let w = GWindow.window () in
  w#show ();
  GMain.main ()
