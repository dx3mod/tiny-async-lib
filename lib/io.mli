(** API for working with system I/O based on {!Engine}. *)

(** {1 Fds} *)

val stdout : Unix.file_descr
val stdin : Unix.file_descr

(** {1 Time} *)

val sleep : float -> unit Promise.t
val interval : float -> (unit -> unit Promise.t) -> unit

(** {1 Files} *)

val read_file : string -> string Promise.t
val write_file : string -> string -> unit Promise.t

(** {1 Read / Write} *)

val read_all : Unix.file_descr -> string Promise.t
val write_all : Unix.file_descr -> string -> unit Promise.t
val read_line : Unix.file_descr -> string Promise.t
