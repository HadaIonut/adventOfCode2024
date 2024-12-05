import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/yielder
import simplifile

fn get_relevant_rules(current, rules) {
  list.fold(rules, [], fn(acc, cur) {
    case string.contains(cur, current) {
      True -> list.append(acc, [cur])
      False -> acc
    }
  })
}

fn is_valid(target, rest, rules) {
  case rest {
    [first, ..rest] -> {
      let relevant_rule =
        list.find(rules, fn(rule) {
          string.contains(rule, target) && string.contains(rule, first)
        })
      case relevant_rule {
        Ok(rule) -> {
          let joined = string.join([target, first], "|")
          case joined == rule {
            True -> is_valid(target, rest, rules)
            False -> False
          }
        }
        Error(_) -> is_valid(target, rest, rules)
      }
    }
    [] -> True
  }
}

fn is_valid_update_batch(list, rules) {
  case list {
    [first, ..rest] -> {
      let relevant = get_relevant_rules(first, rules)
      case is_valid(first, rest, relevant) {
        True -> is_valid_update_batch(rest, rules)
        False -> False
      }
    }
    [] -> True
  }
}

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
  list.sort(update, fn(a, b) {
    let relevant_rule =
      list.find(rules, fn(rule) {
        string.contains(rule, a) && string.contains(rule, b)
      })
      |> result.unwrap("")

    let joined = string.join([a, b], "|")
    case joined == relevant_rule {
      True -> order.Lt
      False -> order.Gt
    }
  })
  |> get_center_elem()
}

pub fn main() {
  let assert [left, right] =
    simplifile.read("./input")
    |> result.unwrap("")
    |> string.split(" \n")

  let rules = left |> string.split("\n") |> list.filter(fn(rule) { rule != "" })
  let updates =
    right
    |> string.split("\n")
    |> list.map(fn(rule) {
      string.split(rule, ",") |> list.filter(fn(rule) { rule != "" })
    })
    |> list.filter(fn(update) { update != [] })

  updates
  |> list.fold(0, fn(acc, update) {
    case is_valid_update_batch(update, rules) {
      True -> {
        get_center_elem(update)
        ""
      }
      False -> {
        sort_by_rules(update, rules)
      }
    }
    |> int.parse()
    |> result.unwrap(0)
    |> int.add(acc)
  })
  |> io.debug()
}
