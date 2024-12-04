import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import simplifile

fn traverse_row_left(mat, x, y, out) {
  let row = yielder.at(mat, x)

  case row {
    Ok(row) -> {
      let col = yielder.at(row, y)

      case col {
        Ok(_) -> {
          let txt =
            row
            |> yielder.drop(y)
            |> yielder.take(4)
            |> yielder.to_list()
            |> string.join("")

          case is_xmas(txt) {
            True -> traverse_row_left(mat, x, y + 1, out + 1)
            False -> traverse_row_left(mat, x, y + 1, out)
          }
        }
        Error(_) -> traverse_row_left(mat, x + 1, 0, out)
      }
    }
    Error(_) -> out
  }
}

fn get_diag_text(mat, cur_val, cur_x, cur_y, sign) {
  let indexes = [
    cur_x,
    cur_y,
    cur_x + 1,
    cur_y + 1 * sign,
    cur_x + 2,
    cur_y + 2 * sign,
    cur_x + 3,
    cur_y + 3 * sign,
  ]

  case list.all(indexes, fn(i) { i >= 0 }) {
    False -> ""
    True -> {
      let rows =
        result.all([
          yielder.at(mat, cur_x + 1),
          yielder.at(mat, cur_x + 2),
          yielder.at(mat, cur_x + 3),
        ])
      case rows {
        Ok([row_1, row_2, row_3]) -> {
          let cols =
            result.all([
              yielder.at(row_1, cur_y + 1 * sign),
              yielder.at(row_2, cur_y + 2 * sign),
              yielder.at(row_3, cur_y + 3 * sign),
            ])

          case cols {
            Ok([val_1, val_2, val_3]) -> {
              string.join([cur_val, val_1, val_2, val_3], "")
            }
            Error(_) -> ""
            Ok(_) -> ""
          }
        }
        Error(_) -> ""
        Ok(_) -> ""
      }
    }
  }
}

fn is_xmas(text) {
  text == "XMAS" || text == "SAMX"
}

fn is_mas(text) {
  text == "MAS" || text == "SAM"
}

pub fn diag_fuckery(mat, x, y, out) {
  let row = yielder.at(mat, x)

  case row {
    Ok(row) -> {
      let col = yielder.at(row, y)

      case col {
        Ok(cur_val) -> {
          let right = get_diag_text(mat, cur_val, x, y, 1)
          let left = get_diag_text(mat, cur_val, x, y, -1)

          case is_xmas(right) {
            True ->
              case is_xmas(left) {
                True -> diag_fuckery(mat, x, y + 1, out + 2)
                False -> diag_fuckery(mat, x, y + 1, out + 1)
              }
            False ->
              case is_xmas(left) {
                True -> diag_fuckery(mat, x, y + 1, out + 1)
                False -> diag_fuckery(mat, x, y + 1, out)
              }
          }
        }
        Error(_) -> diag_fuckery(mat, x + 1, 0, out)
      }
    }
    Error(_) -> out
  }
}

fn get_cross_data(mat, center_val, center_x, center_y) {
  let indecies = [center_x - 1, center_y - 1]

  case list.all(indecies, fn(i) { i >= 0 }) {
    True -> {
      let rows =
        result.all([
          yielder.at(mat, center_x - 1),
          yielder.at(mat, center_x + 1),
        ])
      case rows {
        Ok([up, down]) -> {
          let vals =
            result.all([
              yielder.at(up, center_y - 1),
              yielder.at(up, center_y + 1),
              yielder.at(down, center_y + 1),
              yielder.at(down, center_y - 1),
            ])
          case vals {
            Ok([up_left, up_right, down_right, down_left]) -> {
              [
                string.join([up_left, center_val, down_right], ""),
                string.join([up_right, center_val, down_left], ""),
              ]
            }
            Ok(_) -> ["", ""]
            Error(_) -> ["", ""]
          }
        }
        Ok(_) -> ["", ""]
        Error(_) -> ["", ""]
      }
    }
    False -> ["", ""]
  }
}

fn cross(mat, x, y, out) {
  let row = yielder.at(mat, x)

  case row {
    Ok(row) -> {
      let col = yielder.at(row, y)

      case col {
        Ok(cur_val) -> {
          let assert [left, right] = get_cross_data(mat, cur_val, x, y)

          case is_mas(left) && is_mas(right) {
            True -> cross(mat, x, y + 1, out + 1)
            False -> cross(mat, x, y + 1, out)
          }
        }
        Error(_) -> cross(mat, x + 1, 0, out)
      }
    }
    Error(_) -> out
  }
}

pub fn main() {
  let txt =
    yielder.from_list(
      result.unwrap(simplifile.read("./testInput"), "")
      |> string.split("\n")
      |> list.map(fn(row) { yielder.from_list(string.split(row, "")) }),
    )

  let a = txt |> traverse_row_left(0, 0, 0)

  let b =
    txt
    |> yielder.map(yielder.to_list)
    |> yielder.to_list()
    |> list.transpose()
    |> list.map(yielder.from_list)
    |> yielder.from_list()
    |> traverse_row_left(0, 0, 0)

  let c =
    txt
    |> diag_fuckery(0, 0, 0)

  let d =
    txt
    |> yielder.map(yielder.to_list)
    |> yielder.to_list()
    |> list.transpose()
    |> list.map(yielder.from_list)
    |> yielder.from_list()
    |> diag_fuckery(0, 0, 0)

  io.debug(a + b + c)
  io.debug(a)
  io.debug(b)
  io.debug(c)
  io.debug(d)

  cross(txt, 0, 0, 0) |> io.debug()
}
