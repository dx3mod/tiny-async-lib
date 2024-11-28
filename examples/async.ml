open Tiny_async_lib
open Promise.Infix

let main () =
  Promise.async (fun () ->
      Io.sleep 3.4 >>= fun () -> Io.(write_all stdout) "Hello World\n");

  Promise.async (fun () ->
      Io.sleep 7. >>= fun () -> Io.(write_all stdout) "Hello World 2\n");

  Io.sleep 10.

let () = Engine.run @@ main ()
