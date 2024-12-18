import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_star
import simplifile

pub fn int_parse(string: String) -> Int {
  int.parse(string) |> result.unwrap(0)
}

pub type Pos {
  Pos(x: Int, y: Int)
}

fn print_config(robots, map_x, map_y) {
  let out =
    list.repeat(".", map_y)
    |> list.index_map(fn(_, index_y) {
      list.repeat(".", map_x)
      |> list.index_map(fn(_, index_x) {
        case dict.get(robots, Pos(index_x, index_y)) {
          Ok(val) -> val
          Error(_) -> "."
        }
      })
      |> string.join("")
    })
    |> string.join("\n")

  io.println(out)
}

pub fn p1(obstacles: List(#(Int, Int))) {
  let obs_map =
    obstacles
    |> list.fold(dict.new(), fn(acc, cur) {
      dict.insert(acc, Pos(cur.0, cur.1), "#")
    })

  let res =
    gleam_star.a_star(#(0, 0), #(70, 70), obstacles)
    |> result.unwrap([])

  list.unique(res) |> list.length() |> io.debug()

  res
  |> list.fold(obs_map, fn(acc, cur) {
    dict.insert(acc, Pos(cur.0, cur.1), "O")
  })
  |> print_config(71, 71)
}

pub fn p2(obstacles: List(#(Int, Int))) {
  case obstacles {
    [val, ..res] -> {
      case gleam_star.a_star(#(0, 0), #(70, 70), res) {
        Error(_) -> p2(res)
        Ok(_) -> val
      }
    }
    [] -> #(0, 0)
  }
}

pub fn main() {
  let input =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(row) { row != "" })
    |> list.map(fn(row) {
      let #(left, right) =
        string.split_once(row, ",") |> result.unwrap(#("", ""))

      #(int_parse(left), int_parse(right))
    })

  input |> list.take(12) |> p1

  input |> list.reverse |> p2 |> io.debug
}
