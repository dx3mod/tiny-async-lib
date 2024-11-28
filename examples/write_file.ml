open Tiny_async_lib

let () = Engine.run @@ Io.write_file "heh" Sys.argv.(1)
