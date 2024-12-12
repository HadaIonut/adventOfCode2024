import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam_community/maths/elementary.{logarithm_10}
import simplifile

fn add_to_dict(dict, val, cur_val) {
  dict.upsert(dict, val, fn(x) {
    case x {
      None -> cur_val
      Some(i) -> i + cur_val
    }
  })
}

fn count_digits(val) {
  logarithm_10(int.to_float(val))
  |> result.unwrap(0.0)
  |> float.add(1.0)
  |> float.floor()
  |> float.round()
}

fn evolve_uncached(dict, cur: Int, until: Int) {
  case cur == until {
    True -> dict
    False -> {
      dict.fold(dict, dict.new(), fn(acc, cur_pos, cur_val) {
        let digit_count = count_digits(cur_pos)
        let is_even = int.modulo(digit_count, 2) |> result.unwrap(0)

        case cur_pos {
          0 -> add_to_dict(acc, 1, cur_val)
          _ if is_even == 0 -> {
            let half = digit_count / 2
            let divider =
              int.power(10, int.to_float(half))
              |> result.unwrap(0.0)
              |> float.round()

            let left = cur_pos / divider
            let right = int.modulo(cur_pos, divider) |> result.unwrap(0)

            add_to_dict(acc, left, cur_val) |> add_to_dict(right, cur_val)
          }
          val -> add_to_dict(acc, val * 2024, cur_val)
        }
      })
      |> evolve_uncached(cur + 1, until)
    }
  }
}

pub fn main() {
  simplifile.read("input")
  |> result.unwrap("")
  |> string.trim
  |> string.split(" ")
  |> list.map(fn(a) { int.parse(a) |> result.unwrap(0) })
  |> list.group(fn(n) { n })
  |> dict.map_values(fn(_, b) { list.length(b) })
  |> evolve_uncached(0, 75)
  |> dict.values
  |> int.sum
  |> io.debug
}
