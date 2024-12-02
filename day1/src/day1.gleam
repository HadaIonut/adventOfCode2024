import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let res = simplifile.read("./input")

  let content = case res {
    Ok(content) -> content
    Error(_) -> ""
  }

  let assert [left, right] =
    string.split(content, "\n")
    |> list.map(fn(s) {
      string.split(s, "   ")
      |> list.filter(fn(l) { l != "" })
      |> list.map(fn(s) {
        let assert Ok(val) = int.parse(s)
        val
      })
    })
    |> list.filter(fn(l) { l != [] })
    |> list.fold([[], []], fn(a, b) {
      let assert [left, right] = b
      let assert [source_left, source_right] = a

      [list.append(source_left, [left]), list.append(source_right, [right])]
    })
    |> list.map(fn(l) { list.sort(l, by: int.compare) })

  let occurance_left =
    list.map(left, fn(a) { a * list.count(right, fn(b) { a == b }) })
    |> list.fold(0, fn(a, b) { a + b })

  let diff =
    list.map2(left, right, fn(a, b) { int.absolute_value(a - b) })
    |> list.fold(0, fn(acc, cur) { acc + cur })

  io.debug(diff)
  io.debug(occurance_left)
}
