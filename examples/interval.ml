open Tiny_async_lib

let main () =
  Io.interval 1. (fun () -> Io.(write_all stdout) "x ");

  Io.sleep 5.1

let () = Engine.run @@ main ()
