import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Robot {
  Robot(location: Pos, velocity: Pos)
}

pub fn int_parse(string) {
  int.parse(string) |> result.unwrap(0)
}

pub fn evolve(robots: List(Robot), map_x, map_y) -> List(Robot) {
  list.map(robots, fn(robot) {
    let new_x = case robot.location.x + robot.velocity.x {
      val if val >= map_x -> val - map_x
      val if val < 0 -> map_x + val
      val -> val
    }
    let new_y = case robot.location.y + robot.velocity.y {
      val if val >= map_y -> val - map_y
      val if val < 0 -> map_y + val
      val -> val
    }

    Robot(Pos(new_x, new_y), robot.velocity)
  })
}

pub fn quads(location, map_x, map_y, acc: #(Int, Int, Int, Int)) {
  case location {
    Pos(x, y) if x > map_x / 2 && y > map_y / 2 -> #(
      acc.0 + 1,
      acc.1,
      acc.2,
      acc.3,
    )
    Pos(x, y) if x > map_x / 2 && y < map_y / 2 -> #(
      acc.0,
      acc.1 + 1,
      acc.2,
      acc.3,
    )

    Pos(x, y) if x < map_x / 2 && y > map_y / 2 -> #(
      acc.0,
      acc.1,
      acc.2 + 1,
      acc.3,
    )
    Pos(x, y) if x < map_x / 2 && y < map_y / 2 -> #(
      acc.0,
      acc.1,
      acc.2,
      acc.3 + 1,
    )
    Pos(_, _) -> acc
  }
}

fn print_config(robots, map_x, map_y) {
  let out =
    list.repeat(".", map_y)
    |> list.index_map(fn(_, index_y) {
      list.repeat(".", map_x)
      |> list.index_map(fn(_, index_x) {
        case dict.get(robots, Pos(index_x, index_y)) {
          Ok(_) -> "#"
          Error(_) -> "."
        }
      })
      |> string.join("")
    })
    |> string.join("\n")

  simplifile.append("out", out)
}

pub fn main() {
  let map_x = 101
  let map_y = 103

  let robots =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter_map(fn(row) {
      case row {
        "" -> Error(Nil)
        _ -> {
          let assert [_, a, b] = string.split(row, "=")
          let assert [left, ..] = string.split(a, " ")
          let #(px, py) =
            string.split_once(left, ",") |> result.unwrap(#("", ""))
          let #(vx, vy) = string.split_once(b, ",") |> result.unwrap(#("", ""))

          Ok(Robot(
            Pos(int_parse(px), int_parse(py)),
            Pos(int_parse(vx), int_parse(vy)),
          ))
        }
      }
    })
  let out =
    list.repeat("", 100)
    |> list.fold(robots, fn(acc, _) {
      let new = evolve(acc, map_x, map_y)
      new
    })
    |> list.fold(#(0, 0, 0, 0), fn(acc, cur) {
      quads(cur.location, map_x, map_y, acc)
    })
  io.debug(out.0 * out.1 * out.2 * out.3)

  list.repeat("", 10_000)
  |> list.index_fold(robots, fn(acc, _, index) {
    let new = evolve(acc, map_x, map_y)
    let robot_dict =
      list.map(new, fn(robot) { #(robot.location, robot) })
      |> dict.from_list
    simplifile.append("out", int.to_string(index) <> ":\n")
    print_config(robot_dict, map_x, map_y)
    simplifile.append("out", "\n\n")
    new
  })
}
