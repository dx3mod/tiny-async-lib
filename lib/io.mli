(* Fds *)

val stdout : Unix.file_descr
val stdin : Unix.file_descr

(* Time *)

val sleep : float -> unit Promise.t

(* Files *)

val read_file : string -> string Promise.t
val write_file : string -> string -> unit Promise.t

(* Read / Write *)

val read_all : Unix.file_descr -> string Promise.t
val write_all : Unix.file_descr -> string -> unit Promise.t
val read_line : Unix.file_descr -> string Promise.t
