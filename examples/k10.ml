open Tiny_async_lib

let tasks = List.init 10_000 (fun _ -> Io.sleep 10.)
let _ = Engine.run @@ Promise.join tasks
