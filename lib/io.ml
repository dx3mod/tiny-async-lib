let sleep delay =
  let p, r = Promise.make () in

  Engine.(on_timer instance) delay (fun handler ->
      Engine.stop_handler handler;
      Promise.fulfill r ());

  p

let read_file filename =
  let p, r = Promise.make () in

  let fd = Unix.openfile filename [] 0o0644 in

  let buffer = Buffer.create 1024 in
  let chunk = Bytes.create 1024 in

  let[@inline] string_of_buffer buffer =
    Buffer.to_bytes buffer |> Bytes.unsafe_to_string
  in

  let[@inline] on_finish () =
    Unix.close fd;
    Promise.fulfill r (string_of_buffer buffer)
  in

  let[@inline] on_data bytes_read =
    Buffer.add_subbytes buffer chunk 0 bytes_read
  in

  Engine.(on_readable instance) fd (fun handler ->
      let bytes_read = Unix.read fd chunk 0 (Bytes.length chunk) in

      if bytes_read = 0 then (
        Engine.stop_handler handler;
        on_finish ())
      else on_data bytes_read);

  p
