type 'a t

and 'a state = private
  | Fulfilled of 'a
  | Rejected of exn
  | Pending of 'a callback list

and 'a callback

type 'a resolver

val make : unit -> 'a t * 'a resolver
val state : 'a t -> 'a state

(* Fulfill or Reject *)

val fulfill : 'a resolver -> 'a -> unit
val reject : 'a resolver -> exn -> unit

(* Monadic *)

val return : 'a -> 'a t
val bind : 'a t -> ('a -> 'b t) -> 'b t
val map : ('a -> 'b) -> 'a t -> 'b t

(* Syntax *)

module Infix : sig
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t
end

module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
end

(* Exceptions *)

exception Ri_violated
exception Twice_resolve

(* Other *)

val async : (unit -> 'a t) -> unit
