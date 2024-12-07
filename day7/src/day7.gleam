import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn concat_nums(a, b) {
  { int.to_string(a) <> int.to_string(b) } |> int.parse() |> result.unwrap(0)
}

fn explore_ops(numbers, acc) {
  case numbers {
    [a, ..rest] -> {
      let new_acc =
        list.fold(acc, [], fn(acc, cur) {
          list.append(acc, [cur + a, cur * a, concat_nums(cur, a)])
        })
      explore_ops(rest, new_acc)
    }
    [] -> acc
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
  |> list.filter(fn(operation) {
    let #(total, numers) = operation

    let assert [first, ..rest] = numers
    explore_ops(rest, [first]) |> list.any(fn(el) { el == total })
  })
  |> list.fold(0, fn(acc, cur) {
    let #(total, _) = cur
    total + acc
  })
  |> io.debug()
}
