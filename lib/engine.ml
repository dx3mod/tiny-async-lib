type t = { mutable sleepers : sleeper list }

and sleeper = {
  mutable time : float;
  mutable stopped : bool;
  action : unit -> unit;
}

let enqueue_sleeper t sleeper = t.sleepers <- t.sleepers @ [ sleeper ]

let time_distance ~now t =
  try max 0. ((List.hd t.sleepers).time -. now) with _ -> 0.

type stop_sleeper = unit -> unit

let on_timer t delay action =
  let rec sleeper =
    { time = Unix.gettimeofday () +. delay; stopped = false; action = g }
  and g () =
    sleeper.time <- Unix.gettimeofday () +. delay;
    enqueue_sleeper t sleeper;
    action stop_sleeper
  and stop_sleeper () = sleeper.stopped <- true in

  enqueue_sleeper t sleeper

let rec restart_actions now = function
  | { stopped = true; _ } :: sleepers -> restart_actions now sleepers
  | { time; action; _ } :: sleepers when time <= now ->
      action ();
      restart_actions now sleepers
  | sleepers -> sleepers

let iter (engine : t) =
  let now = Unix.gettimeofday () in

  time_distance ~now engine |> int_of_float |> Unix.sleep;

  let new_sleepers = restart_actions now engine.sleepers in

  engine.sleepers <- new_sleepers

let create () = { sleepers = [] }
let instance = create ()

let rec run p =
  match Promise.state p with
  | Fulfilled value -> value
  | Rejected exc -> raise exc
  | Pending _ ->
      iter instance;
      run p
