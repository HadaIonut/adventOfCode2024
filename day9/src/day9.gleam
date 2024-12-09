import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type BlockType {
  Free
  Data
}

pub fn better_compact(mem, rev_mem, out, target_len) {
  case list.length(out) == target_len {
    True -> out
    False -> {
      let assert [mem_first, ..mem_rest] = mem
      let assert [rev_first, ..rev_rest] = rev_mem

      case mem_first {
        mem_val if mem_val != "." ->
          better_compact(
            mem_rest,
            rev_mem,
            list.append(out, [mem_val]),
            target_len,
          )
        _ -> {
          case rev_first {
            rev_val if rev_val != "." ->
              better_compact(
                mem_rest,
                rev_rest,
                list.append(out, [rev_val]),
                target_len,
              )
            _ -> better_compact(mem, rev_rest, out, target_len)
          }
        }
      }
    }
  }
}

fn compac(mem, to_replace, cur_dist, stop_dist, removed) {
  case cur_dist <= stop_dist {
    True ->
      case mem {
        [".", ..] -> {
          let cur_sec = list.take_while(mem, fn(cur) { cur == "." })
          let extra_removed = list.take(mem, list.length(cur_sec))
          let rest = list.drop(mem, list.length(cur_sec))

          case list.length(cur_sec) >= list.length(to_replace) {
            True ->
              Ok(
                list.flatten([
                  removed,
                  to_replace,
                  list.drop(extra_removed, list.length(to_replace)),
                  list.map(rest, fn(a) {
                    case a == list.first(to_replace) |> result.unwrap("") {
                      True -> "."
                      False -> a
                    }
                  }),
                ]),
              )
            False ->
              compac(
                rest,
                to_replace,
                cur_dist + list.length(cur_sec),
                stop_dist,
                list.append(removed, cur_sec),
              )
          }
        }
        [val, ..rest] ->
          compac(
            rest,
            to_replace,
            cur_dist + 1,
            stop_dist,
            list.append(removed, [val]),
          )
        [] -> Error(Nil)
      }
    False -> Error(Nil)
  }
}

pub fn p2_compact(mem: List(String), rev_mem: List(String)) {
  case rev_mem {
    [".", ..rest] -> p2_compact(mem, rest)
    [val, ..] -> {
      let file = rev_mem |> list.take_while(fn(cur) { cur == val })
      let rest = rev_mem |> list.drop(list.length(file))

      case compac(mem, file, 0, list.length(rest), []) {
        Ok(val) -> {
          p2_compact(val, rest)
        }
        Error(_) -> p2_compact(mem, rest)
      }
    }
    [] -> mem
  }
}

pub fn main() {
  let a =
    simplifile.read("./input")
    |> result.unwrap("")
    |> string.trim()
    |> string.split("")
    |> list.map(fn(el) { int.parse(el) |> result.unwrap(0) })
    |> list.fold(#([], 0, Data), fn(acc, cur) {
      let #(list, latest, block_type) = acc

      case block_type {
        Data -> {
          #(
            list.append(list, int.to_string(latest) |> list.repeat(cur)),
            latest + 1,
            Free,
          )
        }
        Free -> {
          #(list.append(list, list.repeat(".", cur)), latest, Data)
        }
      }
    })

  let dots = list.count(a.0, fn(t) { t == "." })

  let compt =
    better_compact(a.0, list.reverse(a.0), [], list.length(a.0) - dots)

  compt
  |> list.fold(#(0, 0), fn(acc, cur) {
    let #(acc_val, index) = acc
    #({ int.parse(cur) |> result.unwrap(0) } * index + acc_val, index + 1)
  })
  |> io.debug()

  p2_compact(a.0, list.reverse(a.0))
  |> list.fold(#(0, 0), fn(acc, cur) {
    let #(acc_val, index) = acc
    #({ int.parse(cur) |> result.unwrap(0) } * index + acc_val, index + 1)
  })
  |> io.debug()
}
