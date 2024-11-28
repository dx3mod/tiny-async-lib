type t

val create : unit -> t
val instance : t

(* Execute *)

val run : 'a Promise.t -> 'a

(* Timer *)

type stop_sleeper = unit -> unit

val on_timer : t -> float -> (stop_sleeper -> unit) -> unit
