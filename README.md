# tiny-async-lib

Tiny [concurrent I/O] and [promises] library inspired by [Lwt].
It's just an educational project, not for use.

You can think of it as a lightweight mental model of asynchronous frameworks like Lwt, etc. For an understanding of how it really works under the hood.

```ocaml
open Tiny_async_lib
open Promise.Syntax

let main =
  let* () = Io.(write_all stdout) "Hi! What's your name? " in
  let* name = Io.(read_line stdin) in
  Io.(write_all stdout) ("Hello, " ^ name ^ "!\n")

let () = Engine.run main
````

```console
$ dune exec ./examples/hello.exe
Hi! What's your name? Артём      
Hello, Артём!
```

See more examples in [the directory](./examples/). 

## See also

- Chapter [8.7. Promises](https://cs3110.github.io/textbook/chapters/ds/promises.html), where I got my understanding of how to implement promises and how they work
- Beautiful [Lwt's source code](https://github.com/ocsigen/lwt/tree/master/src) with detailed implementation comments
- Whitepaper [Lwt: a Cooperative Thread Library](https://www.irif.fr/~vouillon/publi/lwt.pdf) is a really accessible article to understand the core of Lwt
- Another great resource is the book [Unix system programming in OCaml](https://ocaml.github.io/ocamlunix/) for writing OS-dependent code

## Quick start

For build the library, you should have OCaml 4.14 (LTS) and above, and the Dune build system. No out-of-the-box dependencies are required. 

To play with the source code you can just do it:
```console
$ git clone https://github.com/dx3mod/tiny-async-lib.git
$ cd ./tiny-async-lib
$ dune build
```

Via an interactive toplevel environment using the Utop:
```console
$ dune utop
```

You can also install library using the OPAM package manager:
```console
$ opam tiny-async-lib.dev https://github.com/dx3mod/tiny-async-lib.git
```

Among other things, it is useful to have API references for easy navigation through the library using odoc. 
```console
$ dune build @doc
$ python -m http.server 8080 --directory _build/default/_doc/_html/ 
```
## In Depth

The `Tiny_async_lib` consists of three important parts: **promises**, asynchronous **engine** and **I/O** module.

### Promises

Promise is the first key abstraction, an abstraction for synchronizing program execution in concurrent (non-sequential) evaluations.

In simple terms, it’s an abstraction over callbacks. Promises allow us to build (monadic) sequential evaluations inside non-sequential evaluations.

Typical example of callbacks for asynchronous (non-sequential) code:
```ocaml
let read_two_files (file1, file2) callback = 
  async_read_file file1 (fun _ -> 
    async_read_file file2 (fun _ -> 
      (* ... *)))

read_two_files ("file-1", "file-2") (fun _ -> 
  (* ... *))
```

Same thing, but with promises:

```ocaml
let read_two_files (file1, file2) =
  let* _ = async_read_file file1 in 
  let* _ = async_read_file file2 in 
  (* ... *)

let* _ = read_two_files ("file-1", "file-2") in
(* ... *)
```

A promise is basically an object that acts as a proxy for a result that we don't know yet, usually because we haven't finished computing its value.

It's very much the `lazy_t` type.
```ocaml
# lazy (1 + 1);;
- : int lazy_t = <lazy>
```

A promis can have one of three states: *fulfilled* (contains a value), *rejected* (contains an exception), and *pending* (contains callbacks).

If a promise is fulfilled or rejected, it is called *resolved*.

Callbacks are functions that are called when a promise is resolved.
So when we (monadic) bind, if the promise is in pending state, we add a callback that calls the following monadic sequence when the promise is resolved.

#### Make a promise

Typical pattern of making *raw* promises i. e. wrapping callbacks.

```ocaml
let async_event () = 
  (* The promise is public read-only interface. 
     The resolver is private interface for resolve the promise. *)
  let promise, resolver = Promise.make () in 

  (* Callback wrapping. *)
  on_event (fun event -> 
    (* ... *)
    Promise.fulfill resolver event);

  (* Returns the public interface, promise. *)
  promise
```
Now we can write linear code on how to process the promised value. 
```ocaml
async_event () >>= do_something >>= do_something_yet
```

In details:
```ocaml
# let p = async_event ();;

# Promise.state p;;
- : event Promise.state = Pending []

# p >>= fun _ -> Promise.return ();;

# Promise.state p;;
- : event Promise.state = Pending [<abstr>]
```

### Engine

The second key abstraction and part of the library is an [asynchronous I/O] engine that polls I/O events and dispatches them to handlers. With this we have multiplexed I/O, event subscription, etc.

```ocaml
let sleep delay =
  let promise, resolver = Promise.make () in

  Engine.(on_timer instance) delay (fun handler ->
      Engine.Handler.stop handler;
      Promise.fulfill resolver ());

  promise
```

The engine implemented in the library is based on the (unix) [select] mechanism. Select is very easy to use. It queries read and write ready file descriptors, i.e. those that are ready for processing, and dispatches them to their handlers.

The (typical) asynchronous engine in internals has an [event loop]. At each iteration of the event loop, the engine polls for new events and calls handlers to handle them.

```ocaml
let iter engine =
  (* ... *)

  let readable_fds, writable_fds, _ =
    Unix.select readable_fds writable_fds [] timeout
  in

  engine.sleepers <- restart_sleeper_handlers engine.sleepers ~now;

  invoke_io_handlers engine.wait_readable readable_fds;
  invoke_io_handlers engine.wait_writable writable_fds
```

With all this in place, it is possible to resolve I/O promises. It's not a big deal. We just have to loop the event loop until the promis is resolved.

```ocaml
let rec run promise =
  match Promise.state promise with
  | Fulfilled value -> value
  | Rejected exc -> raise exc
  | Pending _ ->
      Event_loop.iter instance;
      run promise
```

[asynchronous I/O]: https://en.wikipedia.org/wiki/Asynchronous_I/O
[select]: https://en.wikipedia.org/wiki/Select_(Unix)
[event loop]: https://en.wikipedia.org/wiki/Event_loop

### I/O

This part of the library couples promises and engine to do useful programs. There was an example of a `sleep` function earlier. 

Asynchronous engine callback functions (called handlers) are wrapped to create I/O promises. For example, the `write_all` function:

```ocaml
let write_all fd contents =
  let promise, resolver = Promise.make () in

  (* ... *)

  let handler handler = 
    let bytes_write = Unix.write fd bytes !all_bytes_write length in
    (* ... *)
    if !all_bytes_write = length then begin
      (* ... *)
      Promise.fulfill resolver ()
    end
  in

  Engine.(on_writable instance) fd handler;

  promise
```

### Afterword

Enjoy it! :<

## License

It's not very useful code for real things. Many parts of the implementation are lifted from other solutions. It's a crazy mix. Do whatever you want with that code.

[promises]: https://en.wikipedia.org/wiki/Futures_and_promises
[concurrent I/O]: https://en.wikipedia.org/wiki/Asynchronous_I/O
[Lwt]: https://github.com/ocsigen/lwt