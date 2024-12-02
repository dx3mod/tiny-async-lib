type t = Sleeper.t Handler.t list

let empty = []

let insert new_sleeper_handler queue : t =
  let new_sleeper = Handler.context new_sleeper_handler in

  let rec insert : Sleeper.t Handler.t list -> Sleeper.t Handler.t list =
    function
    | [] -> [ new_sleeper_handler ]
    | sleeper_handler :: queue
      when (Handler.context sleeper_handler).sleep_before_time
           > new_sleeper.sleep_before_time ->
        new_sleeper_handler :: sleeper_handler :: queue
    | sleeper_handler :: queue -> sleeper_handler :: insert queue
  in

  insert queue

let min_sleeper : t -> _ option = function
  | [] -> None
  | sleeper_handler :: _ -> Some (Handler.context sleeper_handler)

let fold : ('acc -> Sleeper.t Handler.t -> 'acc) -> 'acc -> t -> 'acc =
  List.fold_left
