type 'a t

and 'a state = private
  | Fulfilled of 'a
  | Rejected of exn
  | Pending of 'a callback list

and 'a callback = 'a state -> unit

type 'a resolver

val make : unit -> 'a t * 'a resolver
val fulfill : 'a t -> 'a -> unit
val reject : 'a t -> exn -> unit
val state : 'a t -> 'a state

(* Monadic *)

val return : 'a -> 'a t
val bind : 'a t -> ('a -> 'b t) -> 'b t
val map : ('a -> 'b) -> 'a t -> 'b t

(* Infix *)

val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t

(* Exceptions *)

exception Ri_violated
exception Twice_resolve
