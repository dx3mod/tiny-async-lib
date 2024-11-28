let sleep delay =
  let p, r = Promise.make () in

  Engine.(on_timer instance) delay (fun stop ->
      stop ();
      Promise.fulfill r ());

  p
