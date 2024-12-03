import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

fn handle_number_list(list) {
  string.split(list, ",")
  |> list.map(fn(num) { result.unwrap(int.parse(num), 0) })
  |> list.fold(1, fn(acc, cur) { acc * cur })
}

fn compute_muls(text) {
  let assert Ok(reg) =
    regexp.compile(
      "mul\\((\\d+,\\d+)\\)",
      regexp.Options(case_insensitive: False, multi_line: True),
    )

  regexp.scan(reg, text)
  |> list.map(fn(match) {
    let regexp.Match(_source, res) = match

    res
    |> option.values()
    |> list.fold(0, fn(acc, cur) { handle_number_list(cur) + acc })
  })
  |> list.fold(0, fn(acc, cur) { acc + cur })
}

pub fn main() {
  let assert Ok(enabled_reg) =
    regexp.compile(
      "(?:^(.*?)don't\\(\\))|(?:do\\(\\)(.*?)don't\\(\\))|(?:do\\(\\)(.*?)$)",
      regexp.Options(case_insensitive: False, multi_line: True),
    )

  let res =
    result.unwrap(simplifile.read("./input"), "")
    |> string.replace("\n", " ")

  let ans =
    regexp.scan(enabled_reg, res)
    |> list.map(fn(enabled_match) {
      let regexp.Match(_source, enabled_sec) = enabled_match

      enabled_sec
      |> option.values()
      |> list.map(compute_muls)
    })
    |> list.flatten()
    |> list.fold(0, fn(acc, cur) { acc + cur })

  io.debug(compute_muls(res))
  io.debug(ans)
}
