type 'a t

val make : action:('a t -> unit) -> ?stop_action:(unit -> unit) -> 'a -> 'a t
val start : _ t -> unit
val stop : _ t -> unit
val is_stopped : _ t -> bool
val context : 'a t -> 'a
