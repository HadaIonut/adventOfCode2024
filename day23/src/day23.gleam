import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub fn p1(global_connections) {
  dict.fold(global_connections, set.new(), fn(acc, computer, connections) {
    list.fold(connections, [], fn(acc, connection) {
      dict.get(global_connections, connection)
      |> result.unwrap([])
      |> list.filter(fn(second_connection) {
        dict.get(global_connections, second_connection)
        |> result.unwrap([])
        |> list.any(fn(conn) { conn == computer })
      })
      |> list.fold([], fn(acc, cur) {
        list.append(acc, [[computer, connection, cur]])
      })
      |> list.append(acc, _)
    })
    |> list.fold(acc, fn(acc, cur) {
      cur
      |> list.sort(string.compare)
      |> set.insert(acc, _)
    })
  })
  |> set.to_list()
  |> list.count(list.any(_, string.starts_with(_, "t")))
  |> io.debug()
}

pub fn get_graph_from_node(global_connections, computer, visited) {
  let connections =
    dict.get(global_connections, computer)
    |> result.unwrap([])
    |> set.from_list()

  let conn_count =
    set.fold(connections, dict.new(), fn(acc, cur) {
      dict.get(global_connections, cur)
      |> result.unwrap([])
      |> set.from_list()
      |> set.intersection(connections, _)
      |> set.size()
      |> dict.insert(acc, cur, _)
    })

  let max =
    dict.fold(conn_count, 0, fn(acc, _, val) {
      case val > acc {
        True -> val
        False -> acc
      }
    })
  dict.filter(conn_count, fn(_, val) { val == max })
}

pub fn main() {
  let global_connections =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.fold(dict.new(), fn(acc, cur) {
      case string.split_once(cur, "-") {
        Ok(#(left, right)) ->
          dict.upsert(acc, left, fn(val) {
            case val {
              option.None -> [right]
              option.Some(list) -> list.append(list, [right])
            }
          })
          |> dict.upsert(right, fn(val) {
            case val {
              option.None -> [left]
              option.Some(list) -> list.append(list, [left])
            }
          })
        Error(_) -> acc
      }
    })
  p1(global_connections)

  let folded =
    dict.fold(global_connections, dict.new(), fn(acc, computer, _) {
      get_graph_from_node(global_connections, computer, set.new())
      |> dict.insert(acc, computer, _)
    })

  let folded =
    dict.fold(folded, dict.new(), fn(acc, computer, connections) {
      dict.fold(connections, connections, fn(acc, com, con) {
        case dict.get(folded, com) {
          Error(_) -> acc
          Ok(val) -> {
            let merged = dict.merge(acc, val)
            let all_equal =
              merged
              |> dict.values()
              |> list.window_by_2()
              |> list.fold(True, fn(acc, cur) { cur.0 == cur.1 && acc })
            case all_equal {
              True -> merged
              False -> acc
            }
          }
        }
      })
      |> dict.insert(acc, computer, _)
    })
  let max =
    dict.fold(folded, 0, fn(acc, computer, connections) {
      let val = dict.fold(connections, 0, fn(acc, cur, val) { acc + val }) / 2

      case val > acc {
        True -> val
        False -> acc
      }
    })

  let maxed =
    dict.filter(folded, fn(computer, connections) {
      let val = dict.fold(connections, 0, fn(acc, cur, val) { acc + val }) / 2
      val == max
    })
    |> dict.values()
    |> list.first()

  case maxed {
    Ok(val) -> dict.keys(val) |> string.join(",") |> io.debug()
    Error(_) -> panic
  }
}
