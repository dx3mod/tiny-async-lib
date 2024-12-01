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
let return value = { state = Fulfilled value }
let state promise = promise.state

(* +-----------------------------------------------------------------+
   | Monadic                                                         |
   +-----------------------------------------------------------------+ *)

let enqueue_callback promise callback =
  match promise.state with
  | Pending callbacks -> promise.state <- Pending (callback :: callbacks)
  | _ -> ()

exception Ri_violated

let resolve_on_callback resolver : _ callback = function
  | Fulfilled value -> fulfill resolver value
  | Rejected exc -> reject resolver exc
  | Pending _ -> raise Ri_violated

and callback_on_fulfilled resolver f : _ callback = function
  | Pending _ -> raise Ri_violated
  | Rejected exc -> reject resolver exc
  | Fulfilled value -> f value

let bind promise f =
  match promise.state with
  | Fulfilled value -> f value
  | Rejected _ -> Obj.magic promise
  | Pending _ ->
      let output_promise, output_resolver = make () in
      enqueue_callback promise
      @@ callback_on_fulfilled output_resolver (fun value ->
             let promise = f value in
             match promise.state with
             | Fulfilled value -> fulfill output_resolver value
             | Rejected exc -> reject output_resolver exc
             | Pending _ ->
                 enqueue_callback promise @@ resolve_on_callback output_resolver);
      output_promise

let ( << ) = Fun.compose

let map f promise =
  match promise.state with
  | Fulfilled value -> { state = Fulfilled (f value) }
  | Rejected _ -> Obj.magic promise
  | Pending _ ->
      let output_promise, output_resolver = make () in
      enqueue_callback promise
      @@ callback_on_fulfilled output_resolver (fulfill output_resolver << f);
      output_promise

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

let aux_generic_join ~iter ~length ~on_fulfilled ~on_complete promises =
  let output_promise, output_resolver = make () in
  let remaining_promises = ref (length promises) in

  let aux_on_complete () =
    if !remaining_promises = 0 then fulfill output_resolver (on_complete ())
  in

  let aux_on_fulfilled value =
    on_fulfilled value;
    decr remaining_promises;
    aux_on_complete ()
  in

  if length promises = 0 then fulfill output_resolver @@ on_complete ()
  else
    iter
      (fun promise ->
        match promise.state with
        | Fulfilled value -> aux_on_fulfilled value
        | Rejected _ -> Obj.magic promise
        | Pending _ ->
            enqueue_callback promise
            @@ callback_on_fulfilled output_resolver aux_on_fulfilled)
      promises;

  output_promise

let aux_list_join () = aux_generic_join ~iter:List.iter ~length:List.length
and aux_array_join () = aux_generic_join ~iter:Array.iter ~length:Array.length

let join promises =
  aux_list_join () ~on_fulfilled:ignore ~on_complete:ignore promises

let join_array promises =
  aux_array_join () ~on_fulfilled:ignore ~on_complete:ignore promises

let all promises =
  let result_values = ref [] in

  aux_list_join ()
    ~on_fulfilled:(fun value -> result_values := value :: !result_values)
    ~on_complete:(fun () -> !result_values)
    promises
