import gleam/float
import gleam/int
import gleam/io
import gleam/list.{filter, find, fold, map, sort}
import gleam/order
import gleam/result
import gleam/string.{contains, join, split}
import gleam/yielder
import simplifile

fn get_center_elem(update) {
  let middle_index =
    { yielder.from_list(update) |> yielder.length() |> int.to_float() } /. 2.0
    |> float.floor()
    |> float.round()

  yielder.from_list(update)
  |> yielder.at(middle_index)
  |> result.unwrap("")
}

fn sort_by_rules(update, rules) {
  sort(update, fn(a, b) {
    let relevant_rule =
      find(rules, fn(rule) { contains(rule, a) && contains(rule, b) })
      |> result.unwrap("")

    case join([a, b], "|") == relevant_rule {
      True -> order.Lt
      False -> order.Gt
    }
  })
}

fn clean_split(lines, separator) {
  lines |> split(separator) |> filter(fn(line) { line != "" })
}

fn process_result(to_process, prev) {
  to_process
  |> get_center_elem()
  |> int.parse()
  |> result.unwrap(0)
  |> int.add(prev)
}

pub fn main() {
  let assert [left, right] =
    simplifile.read("./input")
    |> result.unwrap("")
    |> split(" \n")

  let rules = left |> clean_split("\n")

  right
  |> split("\n")
  |> map(fn(rule) { rule |> clean_split(",") })
  |> filter(fn(update) { update != [] })
  |> fold([0, 0], fn(acc, update) {
    let sorted = sort_by_rules(update, rules)
    let assert [correct, fixed] = acc

    case sorted == update {
      True -> [process_result(sorted, correct), fixed]
      False -> [correct, process_result(sorted, fixed)]
    }
  })
  |> io.debug()
}
