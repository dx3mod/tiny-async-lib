(lang dune 3.7)

(name tiny-async-lib)

(version 0.1)

(generate_opam_files true)

(source
 (github dx3mod/tiny-async-lib))

(authors "Mikhail Lopatin <dx3mod@bk.ru>")

(maintainers "Mikhail Lopatin <dx3mod@bk.ru>")

(license MIT)

(package
 (name tiny-async-lib)
 (synopsis "Tiny concurrent I/O and promises library")
 (depends ocaml dune))
