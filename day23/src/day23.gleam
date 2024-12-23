import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import pocket_watch
import simplifile

pub fn set_any(target, tst_fn) {
  set.fold(target, False, fn(acc, cur) { acc || tst_fn(cur) })
}

pub fn p1(global_connections) {
  use <- pocket_watch.simple("part 1")
  {
    use acc, computer, connections <- dict.fold(global_connections, set.new())
    {
      use acc, connection <- set.fold(connections, acc)

      dict.get(global_connections, connection)
      |> result.unwrap(set.new())
      |> set.filter(fn(second_connection) {
        dict.get(global_connections, second_connection)
        |> result.unwrap(set.new())
        |> set_any(fn(conn) { conn == computer })
      })
      |> set.fold(acc, fn(acc, cur) {
        set.insert(acc, list.sort([computer, connection, cur], string.compare))
      })
    }
  }
  |> set.fold(0, fn(acc, val) {
    use <- bool.guard(list.any(val, string.starts_with(_, "t")), acc + 1)
    acc
  })
  |> io.debug()
}

pub fn get_graph_from_node(global_connections, computer) {
  let connections =
    dict.get(global_connections, computer)
    |> result.unwrap(set.new())

  let conn_count =
    set.fold(connections, dict.new(), fn(acc, cur) {
      dict.get(global_connections, cur)
      |> result.unwrap(set.new())
      |> set.intersection(connections, _)
      |> set.size()
      |> dict.insert(acc, cur, _)
    })

  let max =
    dict.fold(conn_count, 0, fn(acc, _, val) {
      use <- bool.guard(val > acc, val)
      acc
    })
  dict.filter(conn_count, fn(_, val) { val == max })
}

pub fn same_value(merged) {
  merged
  |> dict.values()
  |> list.window_by_2()
  |> list.fold(True, fn(acc, cur) { cur.0 == cur.1 && acc })
}

pub fn get_max_connections(merged_connections) {
  dict.fold(merged_connections, 0, fn(acc, _, connections) {
    let val = dict.fold(connections, 0, fn(acc, _, val) { acc + val }) / 2

    case val > acc {
      True -> val
      False -> acc
    }
  })
}

pub fn p2(global_connections) {
  use <- pocket_watch.simple("part 2")
  let folded =
    dict.fold(global_connections, dict.new(), fn(acc, computer, _) {
      get_graph_from_node(global_connections, computer)
      |> dict.insert(acc, computer, _)
    })

  let folded = {
    use acc, computer, connections <- dict.fold(folded, dict.new())
    {
      use acc, com, _ <- dict.fold(connections, connections)
      let val = dict.get(folded, com) |> result.unwrap(dict.new())

      let merged = dict.merge(acc, val)
      use <- bool.guard(same_value(merged), merged)
      acc
    }
    |> dict.insert(acc, computer, _)
  }

  let max = get_max_connections(folded)

  let maxed =
    dict.filter(folded, fn(_, connections) {
      dict.fold(connections, 0, fn(acc, _, val) { acc + val }) / 2 == max
    })
    |> dict.values()
    |> list.first()
    |> result.unwrap(dict.new())

  dict.keys(maxed) |> string.join(",") |> io.debug()
}

pub fn insert(val, insert) {
  case val {
    option.None -> set.new() |> set.insert(insert)
    option.Some(list) -> set.insert(list, insert)
  }
}

pub fn main() {
  let global_connections = {
    use <- pocket_watch.simple("data collection")
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.fold(dict.new(), fn(acc, cur) {
      use <- bool.guard(cur == "", acc)
      let assert Ok(#(left, right)) = string.split_once(cur, "-")

      dict.upsert(acc, left, insert(_, right))
      |> dict.upsert(right, insert(_, left))
    })
  }

  p1(global_connections)
  p2(global_connections)
}
