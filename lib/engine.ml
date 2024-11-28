type t = {
  mutable sleepers : sleeper handler list;
  wait_readable : io handler Fd_table.t;
  wait_writable : io handler Fd_table.t;
}

and sleeper = { mutable time : float }
and io

and 'a handler = {
  mutable stopped : bool;
  stop_action : unit -> unit;
  action : 'a handler -> unit;
  meta : 'a;
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

let enqueue_sleeper t sleeper = t.sleepers <- t.sleepers @ [ sleeper ]
let enqueue_readable t fd action = Fd_table.add t.wait_readable fd action
let dequeue_readable_action t fd = Fd_table.remove t.wait_readable fd
let enqueue_writable t fd action = Fd_table.add t.wait_writable fd action
let dequeue_writable_action t fd = Fd_table.remove t.wait_writable fd

let time_distance ~now t =
  try max 0. ((List.hd t.sleepers).meta.time -. now) with _ -> 0.

let make_handler ~action meta =
  { stopped = false; action; meta; stop_action = ignore }

let stop_handler handler =
  handler.stopped <- true;
  handler.stop_action ()

(* +-----------------------------------------------------------------+
   | Internal helpers                                                |
   +-----------------------------------------------------------------+ *)

let on_timer t delay action =
  let sleeper = { time = Unix.gettimeofday () +. delay } in

  let action handler =
    sleeper.time <- Unix.gettimeofday () +. delay;
    action handler
  in

  make_handler ~action sleeper |> enqueue_sleeper t

let on_readable t fd action =
  let meta : io = Obj.magic () in

  let handler =
    {
      stopped = false;
      action;
      meta;
      stop_action = (fun () -> dequeue_readable_action t fd);
    }
  in

  enqueue_readable t fd handler

let on_writable t fd action =
  let meta : io = Obj.magic () in

  let handler =
    {
      stopped = false;
      action;
      meta;
      stop_action = (fun () -> dequeue_writable_action t fd);
    }
  in

  enqueue_writable t fd handler

(* +-----------------------------------------------------------------+
   | Event Loop                                                      |
   +-----------------------------------------------------------------+ *)

let rec restart_sleepers now = function
  | { stopped = true; _ } :: sleepers -> restart_sleepers now sleepers
  | ({ meta = { time }; action; _ } as handler) :: sleepers when time <= now ->
      action handler;
      restart_sleepers now sleepers
  | sleepers -> sleepers

let invoke_actions fd_map fds =
  let invoke_action fd =
    let handler = Fd_table.find fd_map fd in
    handler.action handler
  in
  List.iter invoke_action fds

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

  invoke_actions engine.wait_readable readable_fds;
  invoke_actions engine.wait_writable writable_fds

let rec run p =
  match Promise.state p with
  | Fulfilled value -> value
  | Rejected exc -> raise exc
  | Pending _ ->
      iter instance;
      run p
