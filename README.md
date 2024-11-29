# tiny-async-lib

Tiny [concurrent I/O] and [promises] library inspired by [Lwt].
It's just an educational project, not for use.

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

### Documentation 

```console
$ dune build @doc 
$ python -m http.server 8080 --directory _build/default/_doc/_html/
```

### References

- [Lwt] source code
- [CS3110, 8.7. Promises](https://cs3110.github.io/textbook/chapters/ds/promises.html)

[promises]: https://en.wikipedia.org/wiki/Futures_and_promises
[concurrent I/O]: https://en.wikipedia.org/wiki/Asynchronous_I/O
[Lwt]: https://github.com/ocsigen/lwt