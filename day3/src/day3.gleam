import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import simplifile

fn option_cleaner(option) {
  case option {
    option.None -> ""
    option.Some(ligma) -> ligma
  }
}

fn compute_muls(text) {
  let options = regexp.Options(case_insensitive: False, multi_line: True)
  let assert Ok(reg) = regexp.compile("mul\\((\\d+,\\d+)\\)", options)

  regexp.scan(reg, text)
  |> list.map(fn(match) {
    let regexp.Match(_source, res) = match

    res
    |> list.map(option_cleaner)
    |> list.filter(fn(match) { match != "" })
    |> list.fold(0, fn(acc, cur) {
      {
        string.split(cur, ",")
        |> list.map(fn(num) {
          let assert Ok(parsed) = int.parse(num)
          parsed
        })
        |> list.fold(1, fn(acc, cur) { acc * cur })
      }
      + acc
    })
  })
  |> list.fold(0, fn(acc, cur) { acc + cur })
}

pub fn main() {
  let assert Ok(res) = simplifile.read("./input")

  let res = res |> string.replace("\n", " ")

  let assert Ok(enabled_reg) =
    regexp.compile(
      "(?:^(.*?)don't\\(\\))|(?:do\\(\\)(.*?)don't\\(\\))|(?:do\\(\\)(.*?)$)",
      regexp.Options(case_insensitive: False, multi_line: True),
    )

  let ans =
    regexp.scan(enabled_reg, res)
    |> list.map(fn(enabled_match) {
      let regexp.Match(_source, enabled_sec) = enabled_match

      enabled_sec
      |> list.map(option_cleaner)
      |> list.filter(fn(txt) { txt != "" })
      |> list.map(compute_muls)
    })
    |> list.flatten()
    |> list.fold(0, fn(acc, cur) { acc + cur })

  io.debug(compute_muls(res))
  io.debug(ans)
}
