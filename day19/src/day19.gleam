import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import simplifile

pub fn valid_towels(towels, combination) {
  list.filter(towels, string.starts_with(combination, _))
}

pub fn is_possible(towels, combination) {
  case combination {
    "" -> True
    _ -> {
      valid_towels(towels, combination)
      |> list.fold(False, fn(acc, cur) {
        acc
        || {
          string.length(cur)
          |> string.drop_start(combination, _)
          |> is_possible(towels, _)
        }
      })
    }
  }
}

pub fn p1(towels, needed, out) {
  case needed {
    [current, ..rest] ->
      case is_possible(towels, current) {
        True -> [current]
        False -> []
      }
      |> list.append(out)
      |> p1(towels, rest, _)
    [] -> out
  }
}

pub fn count_all_possible(towels, combination, start, cache) {
  use <- memo.memoize(cache, #(combination, start))
  let current = string.drop_start(combination, start)
  use <- bool.guard(current == "", 1)
  let valid = list.filter(towels, string.starts_with(current, _))

  case valid {
    [] -> 0
    val ->
      list.fold(val, 0, fn(acc, cur) {
        acc
        + count_all_possible(
          towels,
          combination,
          start + string.length(cur),
          cache,
        )
      })
  }
}

pub fn p2(towels, needed, out) {
  case needed {
    [current, ..rest] -> {
      use cache <- memo.create()
      count_all_possible(towels, current, 0, cache)
      |> int.add(out)
      |> p2(towels, rest, _)
    }
    [] -> out
  }
}

pub fn main() {
  let #(towels, needed) =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split_once(" \n")
    |> result.unwrap(#("", ""))
  let towels = towels |> string.trim() |> string.split(", ")
  let needed = needed |> string.trim() |> string.split("\n")

  p1(towels, needed, []) |> list.length() |> io.debug()
  p2(towels, needed, 0) |> io.debug()
}
