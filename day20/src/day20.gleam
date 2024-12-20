import gleam/bool
import gleam/deque
import gleam/dict
import gleam/io
import gleam/list
import gleam/queue
import gleam/result
import gleam/set
import gleam/string
import gleam_star
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

pub fn solve_maze(maze: Map, queue, visited) -> Int {
  case deque.pop_front(queue) {
    Error(_) -> panic
    Ok(#(#(val, dist), new_queue)) -> {
      let is_end = { dict.get(maze, val) |> result.unwrap("") } == "E"
      use <- bool.guard(is_end, dist)

      let neigh = neighbors(val)

      let new_queue =
        list.fold(neigh, #(visited, new_queue), fn(acc, neighbor) {
          let neighbor_val = dict.get(maze, neighbor) |> result.unwrap("#")

          case neighbor_val != "#" && !set.contains(visited, neighbor) {
            True -> {
              #(
                set.insert(acc.0, neighbor),
                deque.push_back(acc.1, #(neighbor, dist + 1)),
              )
            }
            False -> acc
          }
        })
      solve_maze(maze, new_queue.1, new_queue.0)
    }
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

  let start =
    dict.fold(map, #(0, 0), fn(acc, pos, val) {
      case val == "S" {
        False -> acc
        True -> pos
      }
    })

  let normal_path_len =
    deque.new()
    |> deque.push_back(#(start, 0))
    |> solve_maze(map, _, set.new())

  dict.fold(map, 0, fn(acc, pos, val) {
    case val == "#" {
      True -> {
        let cheated_dict = dict.insert(map, pos, ".")
        let new_score =
          deque.new()
          |> deque.push_back(#(start, 0))
          |> solve_maze(cheated_dict, _, set.new())

        case normal_path_len - new_score >= 100 {
          True -> acc + 1
          False -> acc
        }
      }
      False -> acc
    }
  })
  |> io.debug()
}
