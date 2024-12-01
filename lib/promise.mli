(** Abstraction for synchronizing program execution in concurrent environment. *)

type 'a t

and 'a state = private
  | Fulfilled of 'a
  | Rejected of exn
  | Pending of 'a callback list

and 'a callback

type 'a resolver

(** {1 Basic} *)

val make : unit -> 'a t * 'a resolver
val state : 'a t -> 'a state

(** {1 Fulfill or Reject} *)

val fulfill : 'a resolver -> 'a -> unit
val reject : 'a resolver -> exn -> unit

(** {1 Monadic} *)

val return : 'a -> 'a t
val bind : 'a t -> ('a -> 'b t) -> 'b t
val map : ('a -> 'b) -> 'a t -> 'b t

(** {2 Syntax} *)

module Infix : sig
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t
end

module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
end

(** {1 Functions} *)

val async : (unit -> 'a t) -> unit
val join : unit t list -> unit t
val all : 'a t list -> 'a list t

(** {1 Exceptions} *)

exception Ri_violated
exception Twice_resolve
