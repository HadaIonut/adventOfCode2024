import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder
import simplifile

fn gradient(list: List(Int), out: List(Int)) -> List(Int) {
  case list {
    [a, b, ..rest] -> {
      gradient(list.append([b], rest), list.append(out, [a - b]))
    }
    [] -> out
    [_] -> out
  }
}

fn same_sign(list: List(Int)) -> Bool {
  case list {
    [a, b, ..rest] -> {
      case { a > 0 && b > 0 } || { a < 0 && b < 0 } {
        True -> same_sign(list.append([b], rest))
        False -> False
      }
    }
    [] -> True
    [_] -> True
  }
}

fn handle2way(prev, val, acc, left_diff) {
  case prev > val {
    True -> is_diff_to_big_2(left_diff, val, acc)
    False ->
      case prev < val {
        False -> acc
        True -> is_diff_to_big_2(left_diff, val, acc)
      }
  }
}

fn is_diff_to_big_2(left_diff, val, acc) {
  case left_diff > 3 {
    False -> list.append(acc, [val])
    True -> acc
  }
}

fn is_diff_to_big_3(left_diff, right_diff, val, acc) {
  case left_diff > 3 && right_diff > 3 {
    False -> list.append(acc, [val])
    True -> acc
  }
}

fn handle3way(prev, val, next, acc, left_diff) {
  let right_diff = int.absolute_value(val - next)

  case prev > val && val > next {
    True -> is_diff_to_big_3(left_diff, right_diff, val, acc)
    False ->
      case prev < val && val < next {
        True -> is_diff_to_big_3(left_diff, right_diff, val, acc)
        False -> acc
      }
  }
}

pub fn main() {
  let assert Ok(res) = simplifile.read("./input")

  let values =
    string.split(res, "\n")
    |> list.filter(fn(s) { s != "" })
    |> list.map(fn(s) {
      string.split(s, " ")
      |> list.map(fn(elem) {
        let assert Ok(out) = int.parse(elem)
        out
      })
    })

  let filtered_input =
    list.map(values, fn(row) {
      let plm =
        yielder.from_list(row)
        |> yielder.index()

      yielder.fold(plm, [], fn(acc, cur) {
        let #(val, index) = cur

        case index {
          0 -> {
            let assert Ok(#(next, _)) = yielder.at(plm, index + 1)

            let out = handle2way(next, val, acc, int.absolute_value(val - next))

            let ligma = case list.length(out) {
              0 -> [next]
              _ -> out
            }
            ligma
          }
          index -> {
            let assert Ok(#(prev, _)) =
              yielder.from_list(acc) |> yielder.index() |> yielder.last()

            let left_diff = int.absolute_value(prev - val)
            case yielder.at(plm, index + 1) {
              Ok(#(next, _)) -> handle3way(prev, val, next, acc, left_diff)
              Error(_) -> handle2way(prev, val, acc, left_diff)
            }
          }
        }
      })
    })

  io.debug(filtered_input)

  let copium =
    list.map2(filtered_input, values, fn(flt, val) {
      let diff = int.absolute_value(list.length(flt) - list.length(val))
      case diff > 2 {
        False -> flt
        True -> []
      }
    })
    |> list.filter(fn(l) { l != [] })

  list.each(copium, io.debug)
  io.debug(list.length(copium))

  let out =
    list.map(copium, fn(row) { gradient(row, []) })
    |> list.count(fn(row) {
      let max_gradient =
        list.fold(row, 0, fn(acc, cur) {
          case int.absolute_value(cur) > acc {
            True -> int.absolute_value(cur)
            False -> int.absolute_value(acc)
          }
        })
      let all_same_sign = same_sign(row)
      all_same_sign && max_gradient < 4
    })
  io.debug(out)
}
