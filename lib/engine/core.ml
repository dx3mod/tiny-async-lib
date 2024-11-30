type t = {
  mutable sleepers : Sleeper_handlers_queue.t;
  wait_readable : io Handler.t Fd_table.t;
  wait_writable : io Handler.t Fd_table.t;
}

and io

(* +-----------------------------------------------------------------+
   | Constructor                                                     |
   +-----------------------------------------------------------------+ *)

let create () =
  {
    sleepers = Sleeper_handlers_queue.empty;
    wait_readable = Fd_table.create 10;
    wait_writable = Fd_table.create 10;
  }

(* +-----------------------------------------------------------------+
   | Internal helpers                                                |
   +-----------------------------------------------------------------+ *)

let enqueue_sleeper_handler engine sleeper_handler =
  engine.sleepers <-
    Sleeper_handlers_queue.insert sleeper_handler engine.sleepers

let add_readable_handler engine fd action =
  Fd_table.add engine.wait_readable fd action

let remove_readable_handler engine fd = Fd_table.remove engine.wait_readable fd

let add_writable_handler engine fd action =
  Fd_table.add engine.wait_writable fd action

let remove_writable_handler engine fd = Fd_table.remove engine.wait_writable fd
let io_context : io = Obj.magic ()
