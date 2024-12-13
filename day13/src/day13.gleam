import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Step {
  Step(x: Int, y: Int)
}

pub type Location {
  Location(x: Int, y: Int)
}

pub type Machine {
  Machine(a_step: Step, b_step: Step, prize: Location)
}

pub fn get_step(txt) -> Step {
  let assert Ok(#(x, next)) =
    { string.split_once(txt, "X+") |> result.unwrap(#("", "")) }.1
    |> string.split_once(",")
  let y = { string.split_once(next, "Y+") |> result.unwrap(#("", "")) }.1
  let x = int.parse(x) |> result.unwrap(0)
  let y = int.parse(y) |> result.unwrap(0)
  Step(x, y)
}

pub fn get_prize(txt) {
  let assert [_, x, y] = string.split(txt, "=")
  let x =
    string.split(x, ", ")
    |> list.first()
    |> result.unwrap("")
    |> int.parse()
    |> result.unwrap(0)
  let y = int.parse(y) |> result.unwrap(0)
  Location(x + 10_000_000_000_000, y + 10_000_000_000_000)
}

pub fn solve_equation(input: Machine) {
  let top_left =
    { input.b_step.y * input.a_step.x - input.a_step.y * input.b_step.x }
    |> int.to_float()
  let bottom_left =
    { input.b_step.y * input.a_step.x }
    |> int.to_float()

  let left = top_left /. bottom_left

  let right =
    int.to_float({
      input.prize.x * input.b_step.y - input.b_step.x * input.prize.y
    })
    /. int.to_float({ input.b_step.y * input.a_step.x })

  let c = right /. left
  let d =
    { int.to_float(input.prize.y) -. c *. int.to_float(input.a_step.y) }
    /. int.to_float(input.b_step.y)

  #(c, d)
}

pub fn is_round(number) {
  float.loosely_equals(float.round(number) |> int.to_float(), number, 0.001)
}

pub fn main() {
  let input =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(a) { a != "" })
    |> list.sized_chunk(3)
    |> list.fold([], fn(acc, chunk) {
      let assert [a, b, c] = chunk
      let a = get_step(a)
      let b = get_step(b)
      let prize = get_prize(c)

      list.append(acc, [Machine(a, b, prize)])
    })

  input
  |> list.filter_map(fn(eq) {
    let #(c, d) = solve_equation(eq)

    case is_round(c) && is_round(d) {
      True -> Ok(float.round(c) * 3 + float.round(d))
      False -> {
        io.println(
          "c: "
          <> float.to_string(c)
          <> " d:"
          <> float.to_string(d)
          <> " "
          <> bool.to_string(is_round(c))
          <> " "
          <> bool.to_string(is_round(d)),
        )
        Error(Nil)
      }
    }
  })
  |> int.sum()
  |> io.debug()
}
