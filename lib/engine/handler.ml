type 'a t = {
  mutable stopped : bool;
  stop_action : unit -> unit;
  action : 'a t -> unit;
  context : 'a;
}

let make ~action ?stop_action context =
  {
    stopped = false;
    action;
    context;
    stop_action = Option.fold ~none:ignore ~some:Fun.id stop_action;
  }

let start handler = handler.action handler

let stop handler =
  handler.stopped <- true;
  handler.stop_action ()

and is_stopped { stopped; _ } = stopped

let context { context; _ } = context
