# tiny-async-lib

Toy implementation of [promises] and [async engine] inspired by [Lwt].  

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

**References**

- [Lwt] source code
- [CS3110, 8.7. Promises](https://cs3110.github.io/textbook/chapters/ds/promises.html)

[promises]: https://en.wikipedia.org/wiki/Futures_and_promises
[async engine]: https://en.wikipedia.org/wiki/Asynchronous_I/O
[Lwt]: https://github.com/ocsigen/lwt