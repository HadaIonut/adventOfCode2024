import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Memory =
  dict.Dict(String, Int)

pub fn and(a, b) {
  case a, b {
    0, 0 -> 0
    0, 1 -> 0
    1, 0 -> 0
    1, 1 -> 1
    _, _ -> panic
  }
}

pub fn or(a, b) {
  case a, b {
    0, 0 -> 0
    0, 1 -> 1
    1, 0 -> 1
    1, 1 -> 1
    _, _ -> panic
  }
}

pub fn xor(a, b) {
  case a, b {
    0, 0 -> 0
    0, 1 -> 1
    1, 0 -> 1
    1, 1 -> 0
    _, _ -> panic
  }
}

pub type Op =
  #(String, String, fn(Int, Int) -> Int, String)

pub fn evolve(input) {
  let #(memory, ops) = input

  ops
  |> list.fold(#(memory, []), fn(acc, cur: Op) {
    let a = dict.get(acc.0, cur.0)
    let b = dict.get(acc.0, cur.1)

    case a, b {
      Ok(a), Ok(b) -> #(dict.insert(acc.0, cur.3, cur.2(a, b)), acc.1)
      _, _ -> #(acc.0, list.append(acc.1, [cur]))
    }
  })
}

pub fn format(res) {
  res
  |> dict.keys()
  |> list.sort(string.compare)
  |> list.fold("", fn(acc, cur) {
    case string.starts_with(cur, "z") {
      True -> acc <> dict.get(res, cur) |> result.unwrap(0) |> int.to_string()
      False -> acc
    }
  })
  |> string.reverse()
  |> int.base_parse(2)
  |> result.unwrap(0)
}

pub fn keep_evolving(input, prev) {
  let cur = evolve(input)
  let formatted = format(cur.0)

  case formatted == prev && cur.1 == [] {
    True -> formatted
    False -> keep_evolving(cur, formatted)
  }
}

pub fn is_io(val) {
  string.starts_with(val, "x")
  || string.starts_with(val, "y")
  || string.starts_with(val, "z")
}

pub fn main() {
  let assert Ok(#(left, right)) =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split_once(" \n")

  let memory =
    left
    |> string.trim()
    |> string.split("\n")
    |> list.fold(dict.new(), fn(acc, cur) {
      let assert Ok(#(left, right)) = cur |> string.split_once(": ")
      dict.insert(acc, left, int.parse(right) |> result.unwrap(-1))
    })

  let right =
    right
    |> string.trim()
    |> string.split("\n")
    |> list.fold([], fn(acc, cur) {
      let assert Ok(#(op, dest)) = string.split_once(cur, " -> ")
      let assert [a, op, b] = string.split(op, " ")

      case dest {
        "z" <> _ if op != "XOR" -> io.debug(cur)
        _ -> cur
      }
      let vals = [is_io(a), is_io(b), is_io(dest)]

      case op == "XOR" && !list.any(vals, fn(val) { val }) {
        True -> {
          io.debug(cur)
        }
        False -> cur
      }

      let op = case op {
        "AND" -> and
        "XOR" -> xor
        "OR" -> or
        _ -> panic
      }
      list.append(acc, [#(a, b, op, dest)])
    })

  let out = keep_evolving(#(memory, right), 0)
  io.debug(out)

  let #(x, y) =
    memory
    |> dict.keys()
    |> list.sort(string.compare)
    |> list.fold(#("", ""), fn(acc, cur) {
      case cur {
        "x" <> _ -> #(
          acc.0 <> dict.get(memory, cur) |> result.unwrap(-1) |> int.to_string(),
          acc.1,
        )
        "y" <> _ -> #(
          acc.0,
          acc.1 <> dict.get(memory, cur) |> result.unwrap(-1) |> int.to_string(),
        )
        _ -> acc
      }
    })

  let x =
    int.base_parse(x, 2)
    |> result.unwrap(0)
  let y =
    int.base_parse(y, 2)
    |> result.unwrap(0)
  int.bitwise_exclusive_or(out, x + y)
  |> int.to_base2()
  |> io.debug()
  int.to_base2(out) |> io.debug()
}
