let restart_sleeper_handlers queue ~now =
  let rec restart_sleeper_handler queue sleeper_handler =
    if Handler.is_stopped sleeper_handler then
      (* dequeue from queue if sleeper_handler is stopped *)
      queue
    else if
      (Handler.context sleeper_handler).Sleeper.sleep_before_time <= now
      (* if it's time to wake up sleeper_handler *)
    then (
      Handler.start sleeper_handler;
      (* check if sleep_handler is stopped after execution *)
      restart_sleeper_handler queue sleeper_handler)
    else
      (* if sleeper is sleep yet *)
      Sleeper_handlers_queue.insert sleeper_handler queue
  in

  Sleeper_handlers_queue.(fold restart_sleeper_handler empty queue)

let invoke_io_handlers fd_map fds =
  let invoke_io_handler fd =
    let handler : Core.io Handler.t = Fd_table.find fd_map fd in
    Handler.start handler
  in
  List.iter invoke_io_handler fds

let iter (engine : Core.t) =
  let now = Unix.gettimeofday () in
  let timeout =
    (* Find out how much time is left before the sleeper should wake up. *)
    Sleeper_handlers_queue.min_sleeper engine.sleepers
    |> Option.fold ~none:0. ~some:(Sleeper.time_left ~now)
  in

  let readable_fds =
    Fd_table.to_seq engine.wait_readable |> Seq.map fst |> List.of_seq
  and writable_fds =
    Fd_table.to_seq engine.wait_writable |> Seq.map fst |> List.of_seq
  in

  let readable_fds, writable_fds, _ =
    Unix.select readable_fds writable_fds [] timeout
  in

  engine.sleepers <- restart_sleeper_handlers engine.sleepers ~now;

  invoke_io_handlers engine.wait_readable readable_fds;
  invoke_io_handlers engine.wait_writable writable_fds
