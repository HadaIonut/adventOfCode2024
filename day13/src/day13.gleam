import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Machine {
  Machine(a_step: Pos, b_step: Pos, prize: Pos)
}

pub type Part {
  Part1
  Part2
}

pub fn get_step(txt) -> Pos {
  let assert Ok(#(x, next)) =
    { string.split_once(txt, "X+") |> result.unwrap(#("", "")) }.1
    |> string.split_once(",")
  let y = { string.split_once(next, "Y+") |> result.unwrap(#("", "")) }.1
  let x = int.parse(x) |> result.unwrap(0)
  let y = int.parse(y) |> result.unwrap(0)
  Pos(x, y)
}

pub fn get_prize(txt, part: Part) {
  let assert [_, x, y] = string.split(txt, "=")
  let x =
    string.split(x, ", ")
    |> list.first()
    |> result.unwrap("")
    |> int.parse()
    |> result.unwrap(0)
  let y = int.parse(y) |> result.unwrap(0)
  case part {
    Part1 -> Pos(x, y)
    Part2 -> Pos(x + 10_000_000_000_000, y + 10_000_000_000_000)
  }
}

pub fn solve_equation(input: Machine) {
  let left =
    int.to_float({
      input.b_step.y * input.a_step.x - input.a_step.y * input.b_step.x
    })
    /. int.to_float({ input.b_step.y * input.a_step.x })

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

pub fn is_round(number, prec) {
  float.loosely_equals(float.round(number) |> int.to_float(), number, prec)
}

pub fn get_machine(chunk, part: Part) {
  let assert [a, b, c] = chunk
  let a = get_step(a)
  let b = get_step(b)
  let prize = get_prize(c, part)
  [Machine(a, b, prize)]
}

pub fn filter_impossible_machines(machine, precision) {
  let #(c, d) = solve_equation(machine)

  case is_round(c, precision) && is_round(d, precision) {
    True -> Ok(float.round(c) * 3 + float.round(d))
    False -> Error(Nil)
  }
}

pub fn p1(list) {
  list
  |> list.fold([], fn(acc, chunk) {
    list.append(acc, get_machine(chunk, Part1))
  })
  |> list.filter_map(fn(eq) { filter_impossible_machines(eq, 0.00000001) })
}

pub fn p2(list) {
  list
  |> list.fold([], fn(acc, chunk) {
    list.append(acc, get_machine(chunk, Part2))
  })
  |> list.filter_map(fn(eq) { filter_impossible_machines(eq, 0.001) })
}

pub fn main() {
  let input =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(a) { a != "" })
    |> list.sized_chunk(3)

  p1(input) |> int.sum() |> io.debug()
  p2(input) |> int.sum() |> io.debug()
}
