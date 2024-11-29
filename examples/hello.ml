open Tiny_async_lib
open Promise.Syntax

let main () =
  let* () = Io.(write_all stdout) "Hi! What's your name? " in
  let* name = Io.(read_line stdin) in
  Io.(write_all stdout) ("Hello, " ^ name ^ "!\n")

let () = Engine.run @@ main ()
