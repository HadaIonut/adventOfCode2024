import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Array2D(a) =
  Dict(Pos, a)

fn from_list_to_array2d(list) -> Array2D(Int) {
  {
    use row, x <- list.index_map(list)
    use cell, y <- list.index_map(row)

    #(Pos(x, y), cell)
  }
  |> list.flatten()
  |> dict.from_list()
}

pub fn get_next_pos(start_pos: Pos) {
  #(
    Pos(start_pos.x + 1, start_pos.y),
    Pos(start_pos.x - 1, start_pos.y),
    Pos(start_pos.x, start_pos.y + 1),
    Pos(start_pos.x, start_pos.y - 1),
  )
}

pub fn solve_branch(map, pos, cur_val) {
  case dict.get(map, pos) {
    Ok(val) ->
      case val - cur_val == 1 {
        True -> explore_trail(map, pos, val)
        False -> []
      }
    Error(_) -> []
  }
}

pub fn explore_trail(map, start_pos: Pos, cur_val) {
  let new_pos = get_next_pos(start_pos)

  case cur_val == 9 {
    True -> [start_pos]
    False -> {
      list.flatten([
        solve_branch(map, new_pos.0, cur_val),
        solve_branch(map, new_pos.1, cur_val),
        solve_branch(map, new_pos.2, cur_val),
        solve_branch(map, new_pos.3, cur_val),
      ])
    }
  }
}

pub fn main() {
  let input =
    simplifile.read("./input")
    |> result.unwrap("")
    |> string.trim()
    |> string.split("\n")
    |> list.filter_map(fn(row) {
      case row {
        "" -> Error(Nil)
        val ->
          string.split(val, "")
          |> list.map(fn(el) { int.parse(el) |> result.unwrap(0) })
          |> Ok()
      }
    })
    |> from_list_to_array2d()

  let exploration_res =
    input
    |> dict.filter(fn(_, val) { val == 0 })
    |> dict.fold([], fn(acc, pos, val) {
      list.append([explore_trail(input, pos, val)], acc)
    })

  exploration_res
  |> list.map(fn(entry) { list.unique(entry) |> list.length() })
  |> int.sum()
  |> io.debug()

  exploration_res
  |> list.map(fn(entry) { list.length(entry) })
  |> int.sum()
  |> io.debug()
}
