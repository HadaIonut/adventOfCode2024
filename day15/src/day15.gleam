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

pub fn direction_from_points(a: Pos, b: Pos) {
  Pos(b.x - a.x, b.y - a.y)
}

pub fn add_direction_to_point(point: Pos, direction: Pos) {
  Pos(point.x + direction.x, point.y + direction.y)
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

pub fn evolve(map, robot: Pos, instruction) {
  case instruction {
    "^" -> handle_direction(map, robot, Pos(robot.x, robot.y - 1))
    "<" -> handle_direction(map, robot, Pos(robot.x - 1, robot.y))
    ">" -> handle_direction(map, robot, Pos(robot.x + 1, robot.y))
    "v" -> handle_direction(map, robot, Pos(robot.x, robot.y + 1))
    _ -> #(map, robot)
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

pub fn main() {
  let #(map, moves) =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split_once(" \n")
    |> result.unwrap(#("", ""))
  let moves = string.split(moves, "")
  let map =
    string.split(map, "\n")
    |> list.index_fold(dict.new(), fn(acc, val, x) {
      string.split(val, "")
      |> list.index_fold(acc, fn(acc, val_y, y) {
        dict.insert(acc, Pos(y, x), val_y)
      })
    })
  let robot =
    dict.filter(map, fn(_, val) { val == "@" })
    |> dict.fold(Pos(0, 0), fn(_, pos, _) { pos })

  let final =
    list.fold(moves, #(map, robot), fn(acc, cur) {
      let #(cur_map, cur_robot) = acc
      evolve(cur_map, cur_robot, cur)
    })

  score(final.0) |> io.debug()
}
