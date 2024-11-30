let restart_sleepers sleeper_handlers_queue ~now =
  let rec restart_sleepers :
      Sleeper_handlers_queue.t -> Sleeper_handlers_queue.t = function
    | { stopped = true; _ } :: sleepers -> restart_sleepers sleepers
    | ({ context = { sleep_before_time; _ }; action; _ } as sleeper) :: sleepers
      when sleep_before_time <= now ->
        action sleeper;
        restart_sleepers
          (if sleeper.stopped then sleepers
           else Sleeper_handlers_queue.insert sleeper sleepers)
    | sleepers -> sleepers
  in

  restart_sleepers sleeper_handlers_queue

let invoke_io_handlers fd_map fds =
  let invoke_io_handler fd =
    let handler : Core.io Handler.t = Fd_table.find fd_map fd in
    handler.action handler
  in
  List.iter invoke_io_handler fds

let iter (engine : Core.t) =
  let now = Unix.gettimeofday () in
  let timeout =
    (* Find out how much time is left before the sleeper should wake up. *)
    Sleeper_handlers_queue.min_sleeper engine.sleepers
    |> Option.fold ~none:0. ~some:(fun ({ sleep_before_time; _ } : Sleeper.t) ->
           max 0. (sleep_before_time -. now))
  in

  let readable_fds =
    Fd_table.to_seq engine.wait_readable |> Seq.map fst |> List.of_seq
  and writable_fds =
    Fd_table.to_seq engine.wait_writable |> Seq.map fst |> List.of_seq
  in

  let readable_fds, writable_fds, _ =
    Unix.select readable_fds writable_fds [] timeout
  in

  engine.sleepers <- restart_sleepers engine.sleepers ~now;

  invoke_io_handlers engine.wait_readable readable_fds;
  invoke_io_handlers engine.wait_writable writable_fds
