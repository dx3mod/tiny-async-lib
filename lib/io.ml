open Promise.Syntax

let sleep delay =
  let p, r = Promise.make () in

  Engine.(on_timer instance) delay (fun handler ->
      Engine.stop_handler handler;
      Promise.fulfill r ());

  p

let interval delay f =
  Engine.(on_timer instance) delay (fun _ -> Promise.async f)

let read_all fd =
  let p, r = Promise.make () in

  let buffer = Buffer.create 1024 in
  let chunk = Bytes.create 1024 in

  let[@inline] string_of_buffer buffer =
    Buffer.to_bytes buffer |> Bytes.unsafe_to_string
  in

  let[@inline] on_finish () = Promise.fulfill r (string_of_buffer buffer) in

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

let read_file filename =
  let fd = Unix.openfile filename [ O_RDONLY ] 0o0644 in

  let* contents = read_all fd in
  Unix.close fd;
  Promise.return contents

let write_all fd contents =
  let p, r = Promise.make () in

  let bytes = Bytes.unsafe_of_string contents
  and length = String.length contents in

  let all_bytes_write = ref 0 in

  Engine.(on_writable instance) fd (fun handler ->
      let bytes_write = Unix.write fd bytes !all_bytes_write length in

      all_bytes_write := !all_bytes_write + bytes_write;

      if !all_bytes_write = length then (
        Engine.stop_handler handler;
        Promise.fulfill r ()));

  p

let write_file filename contents =
  let fd = Unix.openfile filename [ O_WRONLY; O_CREAT ] 0o0644 in

  let* contents = write_all fd contents in
  Unix.close fd;
  Promise.return contents

let stdout = Unix.stdout
and stdin = Unix.stdin

let read_line fd =
  let p, r = Promise.make () in

  let buffer = Buffer.create 30 in
  let char_byte = Bytes.create 1 in

  Engine.(on_readable instance) fd (fun _ ->
      match Unix.read fd char_byte 0 1 with
      | 0 -> Promise.reject r (Failure "")
      | _ -> (
          match Bytes.get_uint8 char_byte 0 |> char_of_int with
          | '\n' ->
              Promise.fulfill r
                (buffer |> Buffer.to_bytes |> Bytes.unsafe_to_string)
          | c -> Buffer.add_char buffer c));

  p
