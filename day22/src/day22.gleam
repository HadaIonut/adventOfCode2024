import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub fn evolve(number) {
  let step_1 = { number * 64 |> int.bitwise_exclusive_or(number) } % 16_777_216
  let step_2 = { step_1 / 32 |> int.bitwise_exclusive_or(step_1) } % 16_777_216

  { step_2 * 2048 |> int.bitwise_exclusive_or(step_2) } % 16_777_216
}

pub fn get_changes(price, repeat) {
  let #(_, _, changes) =
    list.repeat(0, repeat)
    |> list.fold(#(price, 0, []), fn(acc, _) {
      let price = acc.0 % 10
      let price_change = price - acc.1 % 10
      #(evolve(acc.0), acc.0, list.append(acc.2, [#(price, price_change)]))
    })
  list.drop(changes, 1)
}

pub fn accumumate_wins(acc, cur) {
  let wins =
    get_changes(cur, 2000)
    |> list.window(4)
    |> list.fold(#(acc, dict.new()), fn(acc, cur) {
      use <- bool.guard(list.length(cur) != 4, acc)
      let assert [a, b, c, d] = cur
      let series = #(a.1, b.1, c.1, d.1)

      use <- bool.guard(dict.has_key(acc.1, series), acc)

      let new_wins =
        dict.upsert(acc.0, series, fn(val) {
          case val {
            option.None -> d.0
            option.Some(cur) -> cur + d.0
          }
        })
      #(new_wins, dict.insert(acc.1, series, 0))
    })

  wins.0
}

pub fn p1(numbers) {
  numbers
  |> list.fold(0, fn(acc, nr) {
    list.repeat(0, 2000)
    |> list.fold(nr, fn(acc, _) { evolve(acc) })
    |> int.add(acc)
  })
  |> io.debug()
}

pub fn p2(numbers) {
  numbers
  |> list.fold(dict.new(), accumumate_wins)
  |> dict.fold(#(#(0, 0, 0, 0), 0), fn(acc, pos, cur) {
    case cur > acc.1 {
      True -> #(pos, cur)
      False -> acc
    }
  })
  |> io.debug()
}

pub fn main() {
  let numbers =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(a) { int.parse(a) |> result.unwrap(-1) })

  p1(numbers)
  p2(numbers)
}
