import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Map =
  Dict(Pos, String)

pub type Part {
  Part1
  Part2
}

pub fn direction_from_points(a: Pos, b: Pos) {
  Pos(b.x - a.x, b.y - a.y)
}

pub fn add_direction_to_point(point: Pos, direction: Pos) {
  Pos(point.x + direction.x, point.y + direction.y)
}

pub fn add_direction_to_box(box: #(Pos, Pos), direction: Pos) {
  #(
    Pos({ box.0 }.x + direction.x, { box.0 }.y + direction.y),
    Pos({ box.1 }.x + direction.x, { box.1 }.y + direction.y),
  )
}

pub fn can_move(map, cur, direction, times) {
  case dict.get(map, cur) {
    Ok(val) if val == "O" ->
      can_move(
        map,
        add_direction_to_point(cur, direction),
        direction,
        times + 1,
      )
    Ok(val) if val == "." -> #(True, times)
    Ok(val) if val == "#" -> #(False, 0)
    Error(_) -> #(False, 0)
    Ok(_) -> #(False, 0)
  }
}

pub fn can_move_fat_box(map, cur, direction, box_pos: #(Pos, Pos), times) {
  case dict.get(map, box_pos.0), dict.get(map, box_pos.1) {
    Ok(left), Ok(right)
      if { left == "[" || left == "]" } && { right == "]" || right == "[" }
    ->
      can_move_fat_box(
        map,
        add_direction_to_point(cur, direction),
        direction,
        add_direction_to_box(box_pos, direction),
        times + 1,
      )
    Ok(left), Ok(right) if left == "." && right == "." -> #(True, times)
    Ok(left), Ok(right) if { left == "[" || left == "]" } && right == "." ->
      can_move_fat_box(
        map,
        add_direction_to_point(cur, direction),
        direction,
        add_direction_to_box(box_pos, direction),
        times,
      )
    Ok(left), Ok(right) if { right == "[" || right == "]" } && left == "." ->
      can_move_fat_box(
        map,
        add_direction_to_point(cur, direction),
        direction,
        add_direction_to_box(box_pos, direction),
        times,
      )
    Ok(left), Ok(right) if left == "#" && right == "." -> #(False, 0)
    Ok(left), Ok(right) if left == "." && right == "#" -> #(False, 0)
    Ok(left), Ok(right) if left == "#" && right == "#" -> #(False, 0)
    Ok(_), Ok(_) -> #(False, 0)
    Error(_), Error(_) -> #(False, 0)
    Error(_), Ok(_) -> #(False, 0)
    Ok(_), Error(_) -> #(False, 0)
  }
}

pub fn move_boxes(map, robot, direction) {
  let next = add_direction_to_point(robot, direction)
  let #(can, steps) = can_move(map, next, direction, 0)

  case can {
    True -> {
      let moved_boxes =
        list.repeat(".", steps)
        |> list.fold(#(map, next), fn(acc, _) {
          let future = add_direction_to_point(acc.1, direction)

          #(dict.insert(acc.0, future, "O"), future)
        })
      #(
        moved_boxes.0 |> dict.insert(robot, ".") |> dict.insert(next, "@"),
        next,
      )
    }
    False -> #(map, robot)
  }
}

pub fn move_fat_box(map, robot, direction, box_pos: #(Pos, Pos)) {
  let next_robot = add_direction_to_point(robot, direction)
  let next_box = add_direction_to_box(box_pos, direction)
  let #(can, steps) = can_move_fat_box(map, next_robot, direction, next_box, 0)

  io.debug(can)
  io.debug(steps)

  case can {
    True -> {
      let map = dict.insert(map, robot, ".") |> dict.insert(next_robot, "@")

      let moved =
        list.repeat("", steps)
        |> list.fold(#(map, next_box), fn(acc, _) {
          let moved =
            dict.insert(acc.0, acc.1.0, "[") |> dict.insert(acc.1.1, "]")
          let future =
            add_direction_to_box(acc.1, direction)
            |> add_direction_to_box(direction)
          #(moved, future)
        })
      #(moved.0, next_robot)
    }
    False -> #(map, robot)
  }
}

pub fn handle_direction(map, robot, new_pos) {
  case dict.get(map, new_pos) {
    Ok(val) if val == "#" -> #(map, robot)
    Ok(val) if val == "." -> #(
      map
        |> dict.insert(new_pos, "@")
        |> dict.insert(robot, "."),
      new_pos,
    )
    Ok(val) if val == "O" -> {
      move_boxes(map, robot, direction_from_points(robot, new_pos))
    }
    Ok(_) -> #(map, robot)
    Error(_) -> #(map, robot)
  }
}

pub fn handle_direction_p2(map, robot, new_pos: Pos) {
  case dict.get(map, new_pos) {
    Ok(val) if val == "#" -> #(map, robot)
    Ok(val) if val == "." -> #(
      map
        |> dict.insert(new_pos, "@")
        |> dict.insert(robot, "."),
      new_pos,
    )
    Ok(val) if val == "]" -> {
      let left = Pos(new_pos.x - 1, new_pos.y)
      move_fat_box(map, robot, direction_from_points(robot, new_pos), #(
        left,
        new_pos,
      ))
    }
    Ok(val) if val == "[" -> {
      let right = Pos(new_pos.x + 1, new_pos.y)
      move_fat_box(map, robot, direction_from_points(robot, new_pos), #(
        new_pos,
        right,
      ))
    }
    Ok(_) -> #(map, robot)
    Error(_) -> #(map, robot)
  }
}

pub fn evolve(map, robot: Pos, instruction, part: Part) {
  case instruction, part {
    "^", Part1 -> handle_direction(map, robot, Pos(robot.x, robot.y - 1))
    "<", Part1 -> handle_direction(map, robot, Pos(robot.x - 1, robot.y))
    ">", Part1 -> handle_direction(map, robot, Pos(robot.x + 1, robot.y))
    "v", Part1 -> handle_direction(map, robot, Pos(robot.x, robot.y + 1))

    "^", Part2 -> handle_direction_p2(map, robot, Pos(robot.x, robot.y - 1))
    "<", Part2 -> handle_direction_p2(map, robot, Pos(robot.x - 1, robot.y))
    ">", Part2 -> handle_direction_p2(map, robot, Pos(robot.x + 1, robot.y))
    "v", Part2 -> handle_direction_p2(map, robot, Pos(robot.x, robot.y + 1))
    _, _ -> #(map, robot)
  }
}

pub fn print_map(map: Map) {
  let #(max_x, max_y) =
    dict.fold(map, #(0, 0), fn(acc, pos, _) {
      #(
        case pos.x > acc.0 {
          False -> acc.0
          True -> pos.x
        },
        case pos.y > acc.1 {
          False -> acc.1
          True -> pos.y
        },
      )
    })
  list.repeat(".", max_y + 1)
  |> list.index_map(fn(_, y) {
    list.repeat(".", max_x + 1)
    |> list.index_map(fn(_, x) {
      case dict.get(map, Pos(x, y)) {
        Ok(val) -> io.print(val)
        Error(_) -> io.print("")
      }
    })
    io.print("\n")
  })
}

pub fn score(map: Map) {
  dict.fold(map, 0, fn(acc, pos, cur) {
    case cur {
      "O" -> acc + { pos.x + pos.y * 100 }
      _ -> acc
    }
  })
}

pub fn scaled_map(map: String) -> Map {
  string.replace(map, "#", "##")
  |> string.replace("O", "[]")
  |> string.replace(".", "..")
  |> string.replace("@", "@.")
  |> string.split("\n")
  |> list.index_fold(dict.new(), fn(acc, val, x) {
    string.split(val, "")
    |> list.index_fold(acc, fn(acc, val_y, y) {
      dict.insert(acc, Pos(y, x), val_y)
    })
  })
}

pub fn get_map_p1(map: String) -> Map {
  string.split(map, "\n")
  |> list.index_fold(dict.new(), fn(acc, val, x) {
    string.split(val, "")
    |> list.index_fold(acc, fn(acc, val_y, y) {
      dict.insert(acc, Pos(y, x), val_y)
    })
  })
}

pub fn find_robot(map) {
  dict.filter(map, fn(_, val) { val == "@" })
  |> dict.fold(Pos(0, 0), fn(_, pos, _) { pos })
}

pub fn p1(map: String, moves: List(String)) {
  let map = get_map_p1(map)

  let robot = find_robot(map)

  let final =
    list.fold(moves, #(map, robot), fn(acc, cur) {
      let #(cur_map, cur_robot) = acc
      evolve(cur_map, cur_robot, cur, Part1)
    })

  score(final.0) |> io.debug()
}

pub fn main() {
  let #(map, moves) =
    simplifile.read("testInput")
    |> result.unwrap("")
    |> string.split_once(" \n")
    |> result.unwrap(#("", ""))
  let moves = string.split(moves, "")

  p1(map, moves)

  let map_p2 = scaled_map(map)
  let robot = find_robot(map_p2)

  let final =
    list.fold(moves, #(map_p2, robot), fn(acc, cur) {
      let #(cur_map, cur_robot) = acc
      print_map(cur_map)
      evolve(cur_map, cur_robot, cur, Part2)
    })
}
