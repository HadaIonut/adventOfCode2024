import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Garden(a) =
  Dict(Pos, a)

pub type Fences {
  Dict(String, List(#(Int, Int)))
}

fn from_list_to_array2d(list) {
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

fn explore(dict, pos, veg, prev) {
  case dict.get(dict, pos) {
    Ok(val) if val == veg -> #(
      dict.insert(dict, pos, "-"),
      list.append(prev, [#(pos, veg)]),
    )
    _ -> #(dict, prev)
  }
}

fn find_contineous_regions(
  garden,
  veg,
  pos,
  explored: List(#(Pos, String)),
) -> #(Garden(String), List(#(Pos, String))) {
  let next = get_next_pos(pos)

  let a = explore(garden, next.0, veg, [])
  let b = explore(a.0, next.1, veg, a.1)
  let c = explore(b.0, next.2, veg, b.1)
  let d = explore(c.0, next.3, veg, c.1)

  case list.length(d.1) {
    0 -> #(d.0, list.append(explored, d.1))
    _ -> {
      list.fold(d.1, #(d.0, d.1), fn(acc, cur) {
        let out =
          find_contineous_regions(
            acc.0,
            veg,
            cur.0,
            list.append(explored, [cur]),
          )

        #(out.0, list.append(acc.1, out.1) |> list.unique())
      })
    }
  }
}

fn get_zones(garden) {
  dict.fold(garden, #(garden, []), fn(acc, pos, _) {
    case dict.get(acc.0, pos) |> result.unwrap("") {
      "-" -> acc
      val -> {
        let res = find_contineous_regions(acc.0, val, pos, [#(pos, val)])

        let new_garden =
          {
            list.last(res.1)
            |> result.unwrap(#(Pos(0, 0), "-"))
          }.0
          |> dict.insert(res.0, _, "-")

        #(new_garden, list.append(acc.1, [res.1]))
      }
    }
  })
}

fn p1(zones: List(List(#(Pos, String)))) {
  list.fold(zones, 0, fn(acc, zone) {
    let len = list.length(zone)
    let data = list.map(zone, fn(a) { a.0 })

    let perimeter =
      list.fold(zone, [], fn(acc, cur) {
        get_orto_pos(cur.0)
        |> list.filter(fn(a) { !list.contains(data, a) })
        |> list.append(acc)
      })
      |> list.length()

    acc + len * perimeter
  })
}

fn get_orto_pos(pos: Pos) {
  [
    Pos(pos.x + 1, pos.y),
    Pos(pos.x - 1, pos.y),
    Pos(pos.x, pos.y + 1),
    Pos(pos.x, pos.y - 1),
  ]
}

pub fn edging(dict: Garden(String), pos: Pos, dir: Pos) {
  todo
}

fn p2(zones: List(List(#(Pos, String)))) {
  list.fold(zones, 0, fn(acc, zone) {
    io.debug(zone)
    let len = list.length(zone)
    let data = list.map(zone, fn(a) { a.0 })

    let edges =
      list.fold(zone, [], fn(acc, cur) {
        get_orto_pos(cur.0)
        |> list.filter(fn(a) { !list.contains(data, a) })
        |> list.append(acc)
      })

    edges |> list.length() |> io.debug()

    let a = edges |> list.map(fn(a) { #(a, "A") }) |> dict.from_list()

    a
    |> dict.fold(#(0, Pos(-1, -1)), fn(acc, pos, _) {
      let good_gibis =
        get_orto_pos(pos)
        |> list.find(fn(pos) { dict.has_key(a, pos) })
        |> result.unwrap(pos)

      let dir = Pos(pos.x - good_gibis.x, pos.y - good_gibis.y)

      case dir == acc.1 {
        True -> acc
        False -> #(acc.0 + 1, dir)
      }
    })
    |> io.debug()

    let p = 0

    acc + len * p
  })
}

pub fn main() {
  let input =
    simplifile.read("testTestInput")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.map(fn(a) { string.trim(a) |> string.split("") })
    |> list.filter(fn(a) { a != [] })
    |> from_list_to_array2d()

  let zones = get_zones(input)
  p1(zones.1) |> io.debug()
  p2(zones.1) |> io.debug()
}
