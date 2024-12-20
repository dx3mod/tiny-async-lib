type t = Core.t
and engine = Core.t
and sleeper = Sleeper.t
and io = Core.io
and 'a handler = 'a Handler.t

(* +-----------------------------------------------------------------+
   | Constructor                                                     |
   +-----------------------------------------------------------------+ *)

let create = Core.create
and instance = Core.create ()

(* +-----------------------------------------------------------------+
   | On-Handlers                                                     |
   +-----------------------------------------------------------------+ *)

let on_timer engine delay action =
  let sleeper = Sleeper.make ~delay in

  let action handler =
    Sleeper.next_time sleeper;
    action handler
  in

  let handler = Handler.make ~action sleeper in

  Core.enqueue_sleeper_handler engine handler

let make_io_handler ~stop_action ~action =
  Handler.make ~action ~stop_action Core.io_context

let on_readable engine fd action =
  make_io_handler
    ~stop_action:(fun () -> Core.remove_readable_handler engine fd)
    ~action
  |> Core.add_readable_handler engine fd

let on_writable engine fd action =
  make_io_handler
    ~stop_action:(fun () -> Core.remove_writable_handler engine fd)
    ~action
  |> Core.add_writable_handler engine fd

(* +-----------------------------------------------------------------+
   | Main                                                            |
   +-----------------------------------------------------------------+ *)

let rec run promise =
  match Promise.state promise with
  | Fulfilled value -> value
  | Rejected exc -> raise exc
  | Pending _ ->
      Event_loop.iter instance;
      run promise

(* +-----------------------------------------------------------------+
   | Re-Exports                                                      |
   +-----------------------------------------------------------------+ *)

module Handler = Handler
module Event_loop = Event_loop
