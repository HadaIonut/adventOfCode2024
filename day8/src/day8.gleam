import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Array2D(a) =
  Dict(Pos, a)

fn from_list_to_array2d(list) -> Array2D(string) {
  {
    use row, x <- list.index_map(list)
    use cell, y <- list.index_map(row)

    #(Pos(x, y), cell)
  }
  |> list.flatten()
  |> dict.from_list()
}

fn antipole_generator(dict, cur: Pos, dist_x, dist_y, sign) {
  case dict.has_key(dict, cur) {
    False -> yielder.Done
    True -> yielder.Next(cur, Pos(cur.x + dist_x * sign, cur.y + dist_y * sign))
  }
}

fn find_antipoles(dict, a: Pos, b: Pos) {
  #(
    yielder.unfold(a, fn(cur) {
      antipole_generator(dict, cur, { a.x - b.x }, { a.y - b.y }, 1)
    }),
    yielder.unfold(b, fn(cur) {
      antipole_generator(dict, cur, { a.x - b.x }, { a.y - b.y }, -1)
    }),
  )
}

pub fn main() {
  let input =
    simplifile.read("./input")
    |> result.unwrap("")
    |> string.trim()
    |> string.split("\n")
    |> list.map(fn(row) { string.trim(row) |> string.split("") })
    |> from_list_to_array2d()

  dict.fold(input, [], fn(acc, pos, val) {
    case val {
      "." -> acc
      val -> {
        dict.filter(input, fn(_, string) { string == val })
        |> dict.to_list()
        |> list.map(fn(elem) {
          case elem.0 == pos {
            False -> {
              let #(a, b) = find_antipoles(input, pos, elem.0)

              list.append(yielder.to_list(a), yielder.to_list(b))
            }
            True -> []
          }
        })
        |> list.flatten()
        |> list.append(acc)
      }
    }
  })
  |> list.unique()
  |> list.length()
  |> io.debug()
}
