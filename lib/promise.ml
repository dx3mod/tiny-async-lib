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

let fulfill_or_reject p state =
  match p.state with
  | Pending callbacks ->
      p.state <- state;
      List.iter (fun callback -> callback state) callbacks
  | _ -> raise Twice_resolve

let fulfill p value = fulfill_or_reject p (Fulfilled value)
let reject p exc = fulfill_or_reject p (Rejected exc)
let return value = { state = Fulfilled value }
let state p = p.state

(* +-----------------------------------------------------------------+
   | Monadic                                                         |
   +-----------------------------------------------------------------+ *)

let enqueue_callback p callback =
  match p.state with
  | Pending callbacks -> p.state <- Pending (callback :: callbacks)
  | _ -> ()

exception Ri_violated

let callback_on_resolve r = function
  | Fulfilled value -> fulfill r value
  | Rejected exc -> reject r exc
  | Pending _ -> raise Ri_violated

let callback_on_fulfilled r f = function
  | Pending _ -> raise Ri_violated
  | Rejected exc -> reject r exc
  | Fulfilled value -> f value

let bind p f =
  match p.state with
  | Fulfilled value -> f value
  | Rejected _ -> Obj.magic p
  | Pending _ ->
      let output_promise, output_resolver = make () in
      callback_on_fulfilled output_resolver (fun value ->
          let promise = f value in
          match promise.state with
          | Fulfilled value -> fulfill output_resolver value
          | Rejected exc -> reject output_resolver exc
          | Pending _ ->
              enqueue_callback promise (callback_on_resolve output_resolver))
      |> enqueue_callback p;
      output_promise

let ( << ) = Fun.compose

let map f p =
  match p.state with
  | Fulfilled value -> { state = Fulfilled (f value) }
  | Rejected _ -> Obj.magic p
  | Pending _ ->
      let output_promise, output_resolver = make () in
      callback_on_fulfilled output_resolver (fulfill output_resolver << f)
      |> enqueue_callback p;
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
