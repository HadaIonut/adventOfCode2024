import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_star
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Lab =
  Dict(Pos, String)

pub fn print_map(map: Lab) {
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

pub fn get_ortho(point: Pos) {
  [
    Pos(point.x + 1, point.y),
    Pos(point.x - 1, point.y),
    Pos(point.x, point.y + 1),
    Pos(point.x, point.y - 1),
  ]
}

pub fn main() {
  let input =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.index_fold(dict.new(), fn(acc, row, y) {
      string.trim(row)
      |> string.split("")
      |> list.index_fold(acc, fn(acc, val, x) {
        dict.insert(acc, Pos(x, y), val)
      })
    })
  let #(start, end) =
    dict.fold(input, #(Pos(0, 0), Pos(0, 0)), fn(acc: #(Pos, Pos), pos, cur) {
      case cur == "S", cur == "E" {
        True, False -> #(pos, acc.1)
        False, True -> #(acc.0, pos)
        True, True -> acc
        False, False -> acc
      }
    })
  let obstacles =
    dict.filter(input, fn(_, cur) { cur == "#" })
    |> dict.keys()
    |> list.map(fn(pos) { #(pos.x, pos.y) })

  let path =
    gleam_star.a_star(#(start.x, start.y), #(end.x, end.y), obstacles)
    |> result.unwrap([])
  let len = list.length(path)

  list.window(path, 3)
  |> list.fold(0, fn(acc, cur) {
    let assert [a, b, c] = cur

    let diff_1 = #(b.0 - a.0, b.1 - a.1)
    let diff_2 = #(c.0 - b.0, c.1 - b.1)

    case diff_1 == diff_2 {
      False -> acc + 1
      True -> acc
    }
  })
  |> int.multiply(1000)
  |> int.add(len)
  |> io.debug()
}
