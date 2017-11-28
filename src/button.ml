type button =
  | Load
  | Play
  | Pause

let buttons = [Load;Play;Pause]

let size = 80
let begin_x = 485
let y = 500
let padding = 10

let get_location = function
  | Load -> (begin_x, y, size, size)
  | Play -> (begin_x + size + padding, y, size, size)
  | Pause -> (begin_x + (size + padding) * 2, y, size, size)

let point_in_button point button =
  let (x, y, width, height) = get_location button in
  let (pointx, pointy) = point in
  pointx >= x && pointy >= y && pointx <= width && pointy <= height

let get_button point =
  List.find_opt (point_in_button point) buttons
