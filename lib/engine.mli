(** Select-based asynchronous I/O engine.

    Read more about [select] mechanism:

    {{: https://en.wikipedia.org/wiki/Select_(Unix)}}
*)

type t
(** Engine. *)

and 'a handler

(** {1 Execution} *)

val run : 'a Promise.t -> 'a
(** [run promise]  execute the {!instance} of the engine until the [promise] is not resolved. *)

val iter : t -> unit
(** [iter engine] execute step of the engine's event loop. *)

(** {1 Constrictors} *)

val create : unit -> t
val instance : t

(** {1 Handlers} *)

type sleeper
and io

val on_timer : t -> float -> (sleeper handler -> unit) -> unit
(** [on_timer engine delay handler] *)

val on_readable : t -> Unix.file_descr -> (io handler -> unit) -> unit
(** [on_readable engine fd handler] *)

val on_writable : t -> Unix.file_descr -> (io handler -> unit) -> unit
(** [on_writable engine fd handler] *)

(** Stop handler. *)

val stop_handler : 'a handler -> unit
