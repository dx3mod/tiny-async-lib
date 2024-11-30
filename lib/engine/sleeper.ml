type t = { mutable sleep_before_time : float; delay : float }

let make delay = { sleep_before_time = Unix.gettimeofday () +. delay; delay }

and next_time sleeper =
  sleeper.sleep_before_time <- Unix.gettimeofday () +. sleeper.delay
