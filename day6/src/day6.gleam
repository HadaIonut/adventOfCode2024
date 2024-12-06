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

fn walk_mat(mat, x, y, guard_x, guard_y, out: List(task.Task(Int))) {
  let row = yielder.at(mat, x)

  case row {
    Ok(row) -> {
      let val = yielder.at(row, y)

      case val {
        Ok(_) -> {
          io.println(string.join(
            ["x:", int.to_string(x), ", y:", int.to_string(y)],
            "",
          ))
          case x == guard_x && y == guard_y {
            True -> walk_mat(mat, x, y + 1, guard_x, guard_y, out)
            False -> {
              let t =
                task.async(fn() {
                  let res = set_at_location(mat, x, y, "#")
                  let out = case res |> move(guard_x, guard_y) {
                    Error(_) -> 1
                    Ok(_) -> 0
                  }
                  out
                })

              walk_mat(mat, x, y + 1, guard_x, guard_y, list.append(out, [t]))
            }
          }
        }
        Error(_) -> {
          let res =
            out
            |> list.map(task.await_forever)
            |> list.fold(0, int.add)

          io.println(string.join(
            ["x:", int.to_string(x), ", y:", int.to_string(y)],
            "",
          ))
          io.debug(res)
          res + walk_mat(mat, x + 1, 0, guard_x, guard_y, [])
        }
      }
    }
    Error(_) -> 0
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
      let out = val |> yielder.map(yielder.to_list) |> yielder.to_list()

      out
      |> list.flatten()
      |> list.count(fn(a) { a == "a" || a == "b" || a == "c" || a == "d" })
      |> io.debug()
      ""
    }
  }

  walk_mat(input, 0, 0, x, y, [])
  |> io.debug()
}
