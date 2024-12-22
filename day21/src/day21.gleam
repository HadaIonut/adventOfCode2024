import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Keypad =
  dict.Dict(String, Pos)

pub fn make_keypad() {
  dict.new()
  |> dict.insert("A", Pos(0, 0))
  |> dict.insert("0", Pos(0, 1))
  |> dict.insert("1", Pos(1, 2))
  |> dict.insert("2", Pos(1, 1))
  |> dict.insert("3", Pos(1, 0))
  |> dict.insert("4", Pos(2, 2))
  |> dict.insert("5", Pos(2, 1))
  |> dict.insert("6", Pos(2, 0))
  |> dict.insert("7", Pos(3, 2))
  |> dict.insert("8", Pos(3, 1))
  |> dict.insert("9", Pos(3, 0))
}

pub fn make_arrow_pad() {
  dict.new()
  |> dict.insert(">", Pos(0, 0))
  |> dict.insert("v", Pos(0, 1))
  |> dict.insert("<", Pos(0, 2))
  |> dict.insert("A", Pos(1, 0))
  |> dict.insert("^", Pos(1, 1))
}

pub type Res {
  Single(List(String))
  Multiple(List(String), List(String))
}

pub fn move(cur: Pos, dv: Pos, avoid) {
  let x = case dv.x > 0 {
    True -> list.repeat("v", dv.x)
    False -> list.repeat("^", -dv.x)
  }
  let y = case dv.y > 0 {
    True -> list.repeat(">", dv.y)
    False -> list.repeat("<", -dv.y)
  }

  case Pos(cur.x + dv.x, cur.y) == avoid {
    True -> Single(list.flatten([y, x, ["A"]]))
    False ->
      case Pos(cur.x, cur.y + dv.y) == avoid {
        True -> Single(list.flatten([x, y, ["A"]]))
        False ->
          Multiple(list.flatten([x, y, ["A"]]), list.flatten([y, x, ["A"]]))
      }
  }
}

pub type Entity {
  Human(keypad: Keypad, avoid: Pos)
  Robot(keypad: Keypad, avoid: Pos)
}

pub fn get_dirs(
  input,
  controller: dict.Dict(Int, Entity),
  controller_index,
  current_pos,
  out,
) -> List(String) {
  case input, dict.get(controller, controller_index) {
    [cur, ..rest], Ok(ctrl) -> {
      let new_pos = dict.get(ctrl.keypad, cur) |> result.unwrap(Pos(-1, -1))
      let res =
        move(
          current_pos,
          Pos(current_pos.x - new_pos.x, current_pos.y - new_pos.y),
          ctrl.avoid,
        )
      case res {
        Single(val) -> val
        Multiple(a, b) -> {
          let score_a =
            list.append(out, a)
            |> get_dirs(controller, controller_index + 1, Pos(1, 0), [])
            |> list.length()
          let score_b =
            list.append(out, b)
            |> get_dirs(controller, controller_index + 1, Pos(1, 0), [])
            |> list.length()

          case score_a < score_b {
            True -> a
            False -> b
          }
        }
      }
      |> list.append(out, _)
      |> get_dirs(rest, controller, controller_index, new_pos, _)
    }
    [], Ok(_) -> get_dirs(out, controller, controller_index + 1, Pos(1, 0), [])
    [], Error(Nil) -> out
    [_, ..], Error(_) -> input
  }
}

pub fn main() {
  let input =
    simplifile.read("testInput")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.map(fn(a) { string.split(a, "") })
    |> list.filter(fn(a) { a != [] })

  let keypad = make_keypad()
  let arrow_pad = make_arrow_pad()

  let controller =
    dict.new()
    |> dict.insert(0, Human(keypad, Pos(0, 2)))
    |> dict.insert(1, Robot(arrow_pad, Pos(1, 2)))
    |> dict.insert(2, Robot(arrow_pad, Pos(1, 2)))

  list.fold(input, 0, fn(acc, combo) {
    let val =
      list.take(combo, 3)
      |> string.join("")
      |> int.parse()
      |> result.unwrap(-1)

    let len = get_dirs(combo, controller, 0, Pos(0, 0), []) |> list.length()

    io.debug(combo)
    io.debug(len)

    acc + val * len
  })
  |> io.debug()
}
