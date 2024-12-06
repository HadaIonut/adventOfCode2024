import gleam/int
import gleam/io
import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string
import gleam/yielder
import simplifile

fn is_guard(val) {
  val == "^" || val == ">" || val == "V" || val == "<"
}

fn get_val_at_location(mat, x, y) {
  case x < 0 || y < 0 {
    True -> ""
    False ->
      mat
      |> yielder.at(x)
      |> result.unwrap(yielder.empty())
      |> yielder.at(y)
      |> result.unwrap("")
  }
}

fn find_guard(mat, x, y) {
  let row = mat |> yielder.at(x)

  case row {
    Error(_) -> {
      [-1, -1]
    }
    Ok(row) -> {
      let val = row |> yielder.at(y)
      case val {
        Error(_) -> {
          find_guard(mat, x + 1, 0)
        }
        Ok(val) -> {
          case is_guard(val) {
            False -> find_guard(mat, x, y + 1)
            True -> [x, y]
          }
        }
      }
    }
  }
}

fn set_at_location(mat, target_x, target_y, set) {
  let mat = mat |> yielder.map(yielder.to_list) |> yielder.to_list()

  mat
  |> list.index_map(fn(row, row_index) {
    case row_index == target_x {
      False -> row
      True -> {
        row
        |> list.index_map(fn(val, index_val) {
          case index_val == target_y {
            False -> val
            True -> set
          }
        })
      }
    }
    |> yielder.from_list()
  })
  |> yielder.from_list()
}

fn update(
  mat,
  cur_x,
  cur_y,
  new_x,
  new_y,
  cur_marker,
  new_marker,
  rotate_marker,
) {
  case get_val_at_location(mat, new_x, new_y) {
    "#" -> {
      let new_mat = set_at_location(mat, cur_x, cur_y, rotate_marker)
      move(new_mat, cur_x, cur_y) |> Ok()
    }
    cur_val -> {
      case cur_val == cur_marker {
        True -> mat |> Error()
        False -> {
          let new_mat =
            set_at_location(mat, cur_x, cur_y, cur_marker)
            |> set_at_location(new_x, new_y, new_marker)

          move(new_mat, new_x, new_y) |> Ok()
        }
      }
    }
  }
}

fn move(mat, guard_x, guard_y) {
  let guard = get_val_at_location(mat, guard_x, guard_y)
  case guard {
    "^" -> {
      case update(mat, guard_x, guard_y, guard_x - 1, guard_y, "a", "^", ">") {
        Ok(val) -> val
        Error(err) -> Error(err)
      }
    }
    ">" -> {
      case update(mat, guard_x, guard_y, guard_x, guard_y + 1, "b", ">", "V") {
        Ok(val) -> val
        Error(err) -> Error(err)
      }
    }
    "V" -> {
      case update(mat, guard_x, guard_y, guard_x + 1, guard_y, "c", "V", "<") {
        Ok(val) -> val
        Error(err) -> Error(err)
      }
    }
    "<" -> {
      case update(mat, guard_x, guard_y, guard_x, guard_y - 1, "d", "<", "^") {
        Ok(val) -> val
        Error(err) -> Error(err)
      }
    }
    "" -> Ok(mat)
    _ -> Ok(mat)
  }
}

pub fn main() {
  let input =
    simplifile.read("./input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.map(fn(line) { string.split(line, "") })
    |> list.filter(fn(line) { !list.is_empty(line) })
    |> list.map(yielder.from_list)
    |> yielder.from_list()

  let assert [x, y] =
    input
    |> find_guard(0, 0)
    |> io.debug()

  input |> get_val_at_location(x, y) |> io.debug()

  case move(input, x, y) {
    Error(_) -> io.debug("loop detected?")
    Ok(val) -> {
      let out =
        val
        |> yielder.map(fn(row) { row |> yielder.index() |> yielder.to_list() })
        |> yielder.index()
        |> yielder.to_list()

      let explored =
        out
        |> list.fold([], fn(acc, cur) {
          let #(row, x) = cur

          row
          |> list.filter(fn(el) {
            let #(val, y) = el
            val == "a" || val == "b" || val == "c" || val == "d"
          })
          |> list.fold([], fn(acc2, cur2) {
            let #(val, y) = cur2
            list.append(acc2, [#(val, x, y)])
          })
          |> list.append(acc)
        })

      explored
      |> list.window(100)
      |> list.fold([], fn(acc, cur) {
        let out =
          cur
          |> list.fold([], fn(acc, cur) {
            let t =
              task.async(fn() {
                let #(_, swp_x, swp_y) = cur

                case set_at_location(input, swp_x, swp_y, "#") |> move(x, y) {
                  Error(_) -> 1
                  Ok(_) -> 0
                }
              })
            list.append(acc, [t])
          })

        let batch =
          out |> list.fold(0, fn(acc, cur) { acc + task.await_forever(cur) })

        io.debug(batch)

        list.append(acc, [batch])
      })
      |> list.fold(0, int.add)
      |> io.debug()

      ""
    }
  }
}
