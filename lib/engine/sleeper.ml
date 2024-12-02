type t = { mutable sleep_before_time : float; delay : float }

let make ~delay = { sleep_before_time = Unix.gettimeofday () +. delay; delay }

let next_time sleeper =
  sleeper.sleep_before_time <- Unix.gettimeofday () +. sleeper.delay

let time_left sleeper ~now = max 0. (sleeper.sleep_before_time -. now)
