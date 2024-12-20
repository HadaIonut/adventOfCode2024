import gleam/bool
import gleam/deque
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub type Pos =
  #(Int, Int)

pub type Map =
  dict.Dict(Pos, String)

pub fn neighbors(cur: Pos) {
  [
    #(cur.0 + 1, cur.1),
    #(cur.0 - 1, cur.1),
    #(cur.0, cur.1 - 1),
    #(cur.0, cur.1 + 1),
  ]
}

pub fn cheat_jump(cur: Pos) {
  [
    #(cur.0 + 2, cur.1),
    #(cur.0 - 2, cur.1),
    #(cur.0, cur.1 - 2),
    #(cur.0, cur.1 + 2),
  ]
}

pub fn solve_maze(maze: Map, queue, visited) {
  case deque.pop_front(queue) {
    Error(_) -> panic
    Ok(#(#(val, path), new_queue)) -> {
      let is_end = { dict.get(maze, val) |> result.unwrap("") } == "E"
      use <- bool.guard(is_end, path)

      let neigh = neighbors(val)

      let new_queue =
        list.fold(neigh, #(visited, new_queue), fn(acc, neighbor) {
          let neighbor_val = dict.get(maze, neighbor) |> result.unwrap("#")

          case neighbor_val != "#" && !set.contains(visited, neighbor) {
            True -> {
              #(
                set.insert(acc.0, neighbor),
                deque.push_back(acc.1, #(
                  neighbor,
                  list.append(path, [neighbor]),
                )),
              )
            }
            False -> acc
          }
        })
      solve_maze(maze, new_queue.1, new_queue.0)
    }
  }
}

pub fn manhatan_distance() {
  todo
}

pub fn find(target, list, index) {
  case list {
    [val, ..rest] if val == target -> Ok(#(val, index))
    [val, ..rest] -> find(target, rest, index + 1)
    [] -> Error(Nil)
  }
}

pub fn find_any(target_list, list, out) {
  case target_list {
    [val, ..rest] ->
      case find(val, list, 0) {
        Ok(val) -> find_any(rest, list, list.append(out, [val]))
        Error(_) -> find_any(rest, list, out)
      }
    [] -> out
  }
}

pub fn cheat(path, cur_index, out) {
  case path {
    [val, ..rest] -> {
      let inc_count =
        cheat_jump(val)
        |> find_any(rest, [])
        |> list.count(fn(jump) { jump.1 >= 100 })

      cheat(rest, cur_index + 1, out + inc_count)
    }
    [] -> out
  }
}

pub fn main() {
  let map =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.index_fold(dict.new(), fn(acc, cur, index_y) {
      cur
      |> string.split("")
      |> list.index_fold(acc, fn(acc, cur, index_x) {
        dict.insert(acc, #(index_x, index_y), cur)
      })
    })
    |> dict.filter(fn(_, val) { val != "" })

  let #(start, end) =
    dict.fold(map, #(#(0, 0), #(0, 0)), fn(acc, pos, val) {
      case val == "S", val == "E" {
        _, True -> #(acc.0, pos)
        True, _ -> #(pos, acc.1)
        _, _ -> acc
      }
    })

  let normal_path =
    deque.new()
    |> deque.push_back(#(start, []))
    |> solve_maze(map, _, set.new())

  list.append([start], normal_path)
  |> list.append([end])
  |> cheat(0, 0)
  |> io.debug()
}
