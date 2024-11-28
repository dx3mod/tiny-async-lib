type t
and sleeper
and io
and 'a handler

(* Constrictors *)

val create : unit -> t
val instance : t

(* Handlers *)

val stop_handler : 'a handler -> unit
val on_timer : t -> float -> (sleeper handler -> unit) -> unit
val on_readable : t -> Unix.file_descr -> (io handler -> unit) -> unit
val on_writable : t -> Unix.file_descr -> (io handler -> unit) -> unit

(* Execution *)

val iter : t -> unit
val run : 'a Promise.t -> 'a
