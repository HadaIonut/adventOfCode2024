import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn concat(a: Int, b: Int) -> Int {
  list.append(
    int.digits(a, 10) |> result.unwrap([]),
    int.digits(b, 10) |> result.unwrap([]),
  )
  |> int.undigits(10)
  |> result.unwrap(0)
}

fn check(numbers: List(Int), acc: Int, target: Int) -> Bool {
  case numbers {
    [] -> acc == target
    _ if acc > target -> False
    [a, ..rest] -> {
      case check(rest, acc + a, target) {
        True -> True
        False ->
          case check(rest, acc * a, target) {
            True -> True
            False -> check(rest, concat(acc, a), target)
          }
      }
    }
  }
}

pub fn main() {
  let input =
    simplifile.read("./input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(elem) { elem != "" })
    |> list.map(fn(row) {
      let assert [left, right] = string.split(row, ": ")
      let total = int.parse(left) |> result.unwrap(0)
      let nums =
        string.split(right, " ")
        |> list.map(fn(elem) { int.parse(elem) |> result.unwrap(0) })
      #(total, nums)
    })

  input
  |> list.filter_map(fn(op) {
    let #(total, numbers) = op
    let assert [first, ..rest] = numbers

    case check(rest, first, total) {
      True -> Ok(total)
      False -> Error(0)
    }
  })
  |> int.sum()
  |> io.debug()
}
