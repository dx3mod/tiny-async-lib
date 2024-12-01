type 'a t = { mutable state : 'a state }
and 'a state = Fulfilled of 'a | Rejected of exn | Pending of 'a callback list
and 'a callback = 'a state -> unit

type 'a resolver = 'a t

(* +-----------------------------------------------------------------+
   | Basic                                                           |
   +-----------------------------------------------------------------+ *)

let make () =
  let p = { state = Pending [] } in
  (p, p)

let with_make f =
  let promise, resolver = make () in
  f resolver;
  promise

exception Twice_resolve

let assert_is_not_pending promise =
  assert (match promise.state with Pending _ -> true | _ -> false)

let fulfill_or_reject promise state =
  assert_is_not_pending promise;

  match promise.state with
  | Pending callbacks ->
      promise.state <- state;
      List.iter (fun callback -> callback state) callbacks
  | _ -> raise Twice_resolve

let fulfill promise value = fulfill_or_reject promise (Fulfilled value)
let reject promise exc = fulfill_or_reject promise (Rejected exc)
let state promise = promise.state

(* +-----------------------------------------------------------------+
   | Callbacks                                                       |
   +-----------------------------------------------------------------+ *)

let ( << ) = Fun.compose

(** Enqueue the [callback] to the [promise] if it's pending. *)
let enqueue_callback promise callback =
  match promise.state with
  | Pending callbacks -> promise.state <- Pending (callback :: callbacks)
  | _ -> ()

exception Ri_violated
(** Impossible state. *)

(** Create a [callback] with passed handlers. *)
let callback ~on_fulfilled ~on_rejected : _ callback = function
  | Fulfilled value -> on_fulfilled value
  | Rejected exc -> on_rejected exc
  | Pending _ -> raise Ri_violated

(** Create a callback that will resolve the [resolver] when the parent promise is resolved. *)
let resolve_on_callback resolver =
  callback ~on_fulfilled:(fulfill resolver) ~on_rejected:(reject resolver)

(* +-----------------------------------------------------------------+
   | Monadic                                                         |
   +-----------------------------------------------------------------+ *)

let return value = { state = Fulfilled value }

let aux_bind ~on_fulfilled ~on_pending promise =
  match promise.state with
  | Fulfilled value -> on_fulfilled value
  | Rejected _ -> Obj.magic promise
  | Pending _ -> with_make (enqueue_callback promise << on_pending)

let bind promise f =
  let on_pending resolver =
    callback ~on_rejected:(reject resolver) ~on_fulfilled:(fun value ->
        let promise = f value in

        match promise.state with
        | Fulfilled value -> fulfill resolver value
        | Rejected exc -> reject resolver exc
        | Pending _ -> enqueue_callback promise (resolve_on_callback resolver))
  in

  let on_fulfilled = f in

  aux_bind ~on_fulfilled ~on_pending promise

let map f promise =
  let on_fulfilled value = { state = Fulfilled (f value) } in

  let on_pending resolver =
    callback
      ~on_fulfilled:(fulfill resolver << f)
      ~on_rejected:(reject resolver)
  in

  aux_bind ~on_fulfilled ~on_pending promise

(* +-----------------------------------------------------------------+
   | Syntax                                                          |
   +-----------------------------------------------------------------+ *)

module Infix = struct
  let[@inline] ( >>= ) p f = bind p f
  let[@inline] ( >|= ) p f = map f p
end

module Syntax = struct
  let[@inline] ( let* ) p f = bind p f
end

(* +-----------------------------------------------------------------+
   | Other                                                           |
   +-----------------------------------------------------------------+ *)

let async f = f () |> ignore

(* +-----------------------------------------------------------------+
   | Joins                                                           |
   +-----------------------------------------------------------------+ *)

let aux_join ~on_fulfilled ~on_complete promises =
  with_make @@ fun resolver ->
  let remaining_promises = ref (List.length promises) in

  let check_on_complete () =
    if !remaining_promises = 0 then fulfill resolver @@ on_complete ()
  in

  let on_fulfilled value =
    on_fulfilled value;
    decr remaining_promises;
    check_on_complete ()
  in

  let join_promise promise =
    match promise.state with
    | Fulfilled value -> on_fulfilled value
    | Rejected exc -> reject resolver exc
    | Pending _ ->
        enqueue_callback promise
        @@ callback ~on_fulfilled ~on_rejected:(reject resolver)
  in

  if List.is_empty promises then check_on_complete ()
  else List.iter join_promise promises

let join promises = aux_join ~on_fulfilled:ignore ~on_complete:ignore promises

let all promises =
  let result_values = ref [] in

  aux_join
    ~on_fulfilled:(fun value -> result_values := value :: !result_values)
    ~on_complete:(fun () -> !result_values)
    promises
