(** Select-based asynchronous I/O engine.

    Read more about [select] mechanism:

    {{: https://en.wikipedia.org/wiki/Select_(Unix)}}
*)

type t
(** Engine. *)

val instance : t

(** {1 Constructor} *)

val create : unit -> t

(** {1 Executor} *)

val run : 'a Promise.t -> 'a
(** [run promise] and returns the result of a resolved promise.
  {[
  # Engine.run @@ Promise.return ">_<"
  - : string = ">_<"
  ]}

  See also {!Event_loop}.
*)

(** {1 Handlers} *)

(** Abstraction over callbacks that is invoked when an event occurs within its context. *)
module Handler : sig
  type 'context t

  val stop : _ t -> unit
  (** [stop handler] is no longer called.  *)
end

type 'context handler = 'context Handler.t

(** Handler types/contexts.  *)

type sleeper
and io

(** {2 On events handlers}  *)

(** {3 Time}  *)

val on_timer : t -> float -> (sleeper handler -> unit) -> unit
(** [on_timer engine delay handler] *)

(** {3 I/O}  *)

val on_readable : t -> Unix.file_descr -> (io handler -> unit) -> unit
(** [on_readable engine fd handler] *)

val on_writable : t -> Unix.file_descr -> (io handler -> unit) -> unit
(** [on_writable engine fd handler] *)

(** {1 Internals} *)

type engine
(** Another type alias for Engine. *)

module Event_loop : sig
  val iter : engine -> unit
  (** [iter engine] execute event loop iteration: poll I/O events and handle them. *)
end
