type t = {
  mutable sleepers : sleeper handler list;
  wait_readable : io handler Fd_table.t;
  wait_writable : io handler Fd_table.t;
}

and sleeper = { mutable sleep_before_time : float }
and io

and 'a handler = {
  mutable stopped : bool;
  stop_action : unit -> unit;
  action : 'a handler -> unit;
  context : 'a;
}

(* +-----------------------------------------------------------------+
   | Constructor                                                     |
   +-----------------------------------------------------------------+ *)

let create () =
  {
    sleepers = [];
    wait_readable = Fd_table.create 10;
    wait_writable = Fd_table.create 10;
  }

let instance = create ()

(* +-----------------------------------------------------------------+
   | Internal helpers                                                |
   +-----------------------------------------------------------------+ *)

let rec insert_sleeper sleeper_handler = function
  | [] -> [ sleeper_handler ]
  | ({ context = { sleep_before_time }; _ } as sleeper') :: sleepers
    when sleep_before_time > sleeper_handler.context.sleep_before_time ->
      sleeper_handler :: sleeper' :: sleepers
  | sleeper' :: sleepers -> sleeper' :: insert_sleeper sleeper_handler sleepers

let enqueue_sleeper_handler engine sleeper =
  engine.sleepers <- insert_sleeper sleeper engine.sleepers

let add_readable_handler engine fd action =
  Fd_table.add engine.wait_readable fd action

let remove_readable_handler engine fd = Fd_table.remove engine.wait_readable fd

let add_writable_handler engine fd action =
  Fd_table.add engine.wait_writable fd action

let remove_writable_handler engine fd = Fd_table.remove engine.wait_writable fd

let time_distance ~now engine =
  try
    let first_sleeper = (List.hd engine.sleepers).context in
    max 0. (first_sleeper.sleep_before_time -. now)
  with _ -> 0.

let make_handler ~action context =
  { stopped = false; action; context; stop_action = ignore }

let stop_handler handler =
  handler.stopped <- true;
  handler.stop_action ()

(* +-----------------------------------------------------------------+
   | On-Handlers                                                     |
   +-----------------------------------------------------------------+ *)

let on_timer engine delay action =
  let next_sleep_before_time () = Unix.gettimeofday () +. delay in

  let sleeper = { sleep_before_time = next_sleep_before_time () } in

  let action handler =
    sleeper.sleep_before_time <- next_sleep_before_time ();
    action handler
  in

  make_handler ~action sleeper |> enqueue_sleeper_handler engine

let io_context : io = Obj.magic ()

let on_readable engine fd action =
  {
    stopped = false;
    action;
    context = io_context;
    stop_action = (fun () -> remove_readable_handler engine fd);
  }
  |> add_readable_handler engine fd

let on_writable engine fd action =
  {
    stopped = false;
    action;
    context = io_context;
    stop_action = (fun () -> remove_writable_handler engine fd);
  }
  |> add_writable_handler engine fd

(* +-----------------------------------------------------------------+
   | Event Loop                                                      |
   +-----------------------------------------------------------------+ *)

let rec restart_sleepers now = function
  | { stopped = true; _ } :: sleepers -> restart_sleepers now sleepers
  | ({ context = { sleep_before_time }; action; _ } as sleeper) :: sleepers
    when sleep_before_time <= now ->
      action sleeper;
      restart_sleepers now
        (if sleeper.stopped then sleepers else insert_sleeper sleeper sleepers)
  | sleepers -> sleepers

let invoke_io_handlers fd_map fds =
  let invoke_io_handler fd =
    let handler : io handler = Fd_table.find fd_map fd in
    handler.action handler
  in
  List.iter invoke_io_handler fds

let iter (engine : t) =
  let now = Unix.gettimeofday () in
  let timeout = time_distance ~now engine in

  let readable_fds =
    Fd_table.to_seq engine.wait_readable |> Seq.map fst |> List.of_seq
  and writable_fds =
    Fd_table.to_seq engine.wait_writable |> Seq.map fst |> List.of_seq
  in

  let readable_fds, writable_fds, _ =
    Unix.select readable_fds writable_fds [] timeout
  in

  engine.sleepers <- restart_sleepers now engine.sleepers;

  invoke_io_handlers engine.wait_readable readable_fds;
  invoke_io_handlers engine.wait_writable writable_fds

let rec run p =
  match Promise.state p with
  | Fulfilled value -> value
  | Rejected exc -> raise exc
  | Pending _ ->
      iter instance;
      run p
