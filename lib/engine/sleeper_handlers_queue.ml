type t = Sleeper.t Handler.t list

let empty = []

let insert new_sleeper_handler queue : t =
  let rec insert : Sleeper.t Handler.t list -> Sleeper.t Handler.t list =
    function
    | [] -> [ new_sleeper_handler ]
    | ({ context = { sleep_before_time; _ }; _ } as sleeper_handler) :: queue
      when sleep_before_time > new_sleeper_handler.context.sleep_before_time ->
        new_sleeper_handler :: sleeper_handler :: queue
    | sleeper_handler :: queue -> sleeper_handler :: insert queue
  in

  insert queue

let min_sleeper : t -> _ option = function
  | [] -> None
  | x :: _ -> Some x.Handler.context
