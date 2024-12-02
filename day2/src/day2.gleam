import gleam/int
import gleam/io
import gleam/iterator
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

fn is_safe(row) {
  let max_gradient =
    list.fold(row, 0, fn(acc, cur) {
      case int.absolute_value(cur) > acc {
        True -> int.absolute_value(cur)
        False -> int.absolute_value(acc)
      }
    })
  let all_same_sign = same_sign(row)
  let out = all_same_sign && max_gradient < 4

  out
}

fn is_safe_2(row) {
  let assert [left, right] = row

  let out = !{ int.absolute_value(left - right) > 3 }
  out
}

fn filter_deez(values) {
  list.map(values, fn(set) {
    let iter = yielder.from_list(set) |> yielder.index()

    yielder.fold(iter, [], fn(acc, cur_iter) {
      let #(cur, index) = cur_iter

      case index {
        0 -> {
          let assert Ok(#(second, _)) = yielder.at(iter, 1)
          let assert Ok(#(next2, _)) = yielder.at(iter, index + 2)

          case is_safe(gradient([cur, second, next2], [])) {
            False -> [second]
            True -> [cur]
          }
        }
        index -> {
          let next_res = yielder.at(iter, index + 1)

          case list.reverse(acc) {
            [prev, prev_prev, ..] -> {
              case is_safe(gradient([prev_prev, prev, cur], [])) {
                True -> list.append(acc, [cur])
                False -> acc
              }
            }
            [prev] ->
              case next_res {
                Ok(#(next, _)) -> {
                  case is_safe(gradient([prev, cur, next], [])) {
                    True -> list.append(acc, [cur])
                    False -> acc
                  }
                }
                Error(_) -> {
                  case is_safe_2([prev, cur]) {
                    True -> list.append(acc, [cur])
                    False -> acc
                  }
                }
              }
            [] -> {
              let assert Ok(#(next, _)) = next_res
              let assert Ok(#(next2, _)) = yielder.at(iter, index + 2)

              case is_safe(gradient([cur, next, next2], [])) {
                True -> {
                  list.append(acc, [cur])
                }
                False -> []
              }
            }
          }
        }
      }
    })
  })
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

  io.debug(filter_deez(values))

  io.debug(
    list.map2(filter_deez(values), values, fn(a, b) {
      list.length(b) - list.length(a) < 2
    })
    |> list.count(fn(a) { a }),
  )

  let out =
    list.map(filter_deez(values), fn(row) { gradient(row, []) })
    |> list.count(is_safe)
  io.debug(out)
}
