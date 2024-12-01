open Tiny_async_lib
open Promise.Syntax

let () =
  Engine.run
  @@
  let filenames =
    Array.sub Sys.argv 1 (Array.length Sys.argv - 1) |> Array.to_list
  in

  let readers = List.map Io.read_file filenames in

  let* contents = Promise.all readers in

  List.iter print_endline contents;

  Promise.return ()
