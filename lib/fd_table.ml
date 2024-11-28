module T = Hashtbl.Make (struct
  type t = Unix.file_descr

  let equal = ( == )
  let hash t = Int.hash @@ Obj.magic t
end)

include T
