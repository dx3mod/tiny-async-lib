open Tiny_async_lib
open Promise.Syntax

let () =
  Engine.run
  @@
  let* contents = Io.read_file Sys.argv.(1) in

  print_string contents;

  Promise.return ()
