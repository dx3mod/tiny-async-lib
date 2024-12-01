(** Abstraction for synchronizing program execution in concurrent environment. 

  In simple terms, it’s an abstraction over callbacks. It allows us to build 
  (monadic) sequence evaluations inside non-sequence evaluations and synchronize them.

  Example of monadic sequence evaluations:
  {[
    let* a = async_do_a () in 
    let* b = async_do_b () in 
    (* ... *)
    return ()
  ]}

  *)

type 'a t
(** Read-only promise type. *)

(** Promise state. *)
and 'a state = private
  | Fulfilled of 'a
  | Rejected of exn
  | Pending of 'a callback list

and 'a callback
(** Type for internal use. *)

type 'a resolver
(** "Private" interface to resolve (write state to) a promise. 
    This is done so that the user cannot resolve our promise and thus break it.
    So we have two types to read and write in promise. *)

(** {1 Constructor} *)

val make : unit -> 'a t * 'a resolver
(** [make ()] returns a {{!t} promise} and a {{!resolver} resolver}. 

    Basic pattern:
    {[
      let async_do_something _ = 
        let promise, resolver = Promise.make () in 

        on_event (fun event ->
           (* ... *)
           Promise.fulfill resolver _);

        promise
    ]}

*)

val with_make : ('a resolver -> unit) -> 'a t

val state : 'a t -> 'a state
(** [state promise] returns the current inner {!type-state} of the [promise].  *)

(** {1 Fulfill or Reject} *)

val fulfill : 'a resolver -> 'a -> unit
(** [fulfill resolver value]

    @raise Twice_resolve if the promise is not {{!Pending} pending} *)

val reject : 'a resolver -> exn -> unit
(** [reject resolver exc]

    @raise Twice_resolve if the promise is not {{!Pending} pending} *)

(** {1 Monadic} *)

val return : 'a -> 'a t
(** [return value] returns a {{!Fulfilled} fulfilled} promise with the [value] passed.  *)

val bind : 'a t -> ('a -> 'b t) -> 'b t
val map : ('a -> 'b) -> 'a t -> 'b t

(** {2 Syntax} *)

module Infix : sig
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  (** See {!bind}. *)

  val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t
  (** See {!map}. *)
end

module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  (** See {!bind}. *)
end

(** {1 Functions} *)

(** {2 Async} *)

val async : (unit -> 'a t) -> unit

(** {2 Joins} *)

val join : unit t list -> unit t
(** [join promises] waits until all [promises] are resolved. *)

val all : 'a t list -> 'a list t
(** [all promises] waits until all promises have been resolved and returns resolved values. *)

(** {1 Exceptions} *)

exception Twice_resolve
(** Raise if you try to resolve a promise twice. *)
