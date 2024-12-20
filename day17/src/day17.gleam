import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type RegisterType {
  A
  B
  C
}

pub type Memory =
  dict.Dict(RegisterType, Int)

pub fn get_op_value(operand, memory) {
  case operand {
    val if val >= 0 && operand <= 3 -> operand
    4 -> dict.get(memory, A) |> result.unwrap(0)
    5 -> dict.get(memory, B) |> result.unwrap(0)
    6 -> dict.get(memory, C) |> result.unwrap(0)
    7 -> -1
    _ -> 0
  }
}

pub fn adv(operand, memory, insert_pos) {
  let mem = get_op_value(operand, memory)
  let cur_a = dict.get(memory, A) |> result.unwrap(0)

  let power =
    int.power(2, int.to_float(mem))
    |> result.unwrap(0.0)
    |> float.round()

  dict.insert(memory, insert_pos, cur_a / power)
}

pub fn compute_byte_code(
  program,
  memory: Memory,
  instruction_counter,
  out: List(Int),
  original_program,
) {
  case program {
    [opcode, operand, ..rest] -> {
      case opcode {
        0 -> {
          compute_byte_code(
            rest,
            adv(operand, memory, A),
            instruction_counter + 1,
            out,
            original_program,
          )
        }
        1 -> {
          let op_val = operand
          let cur_b = dict.get(memory, B) |> result.unwrap(0)
          let new_mem =
            dict.insert(memory, B, int.bitwise_exclusive_or(cur_b, op_val))

          compute_byte_code(
            rest,
            new_mem,
            instruction_counter + 1,
            out,
            original_program,
          )
        }
        2 -> {
          let op_val = get_op_value(operand, memory)
          let new_mem = dict.insert(memory, B, op_val % 8)

          compute_byte_code(
            rest,
            new_mem,
            instruction_counter + 1,
            out,
            original_program,
          )
        }
        3 -> {
          let mem = operand

          let cur_a = dict.get(memory, A) |> result.unwrap(0)

          case cur_a {
            0 ->
              compute_byte_code(
                rest,
                memory,
                instruction_counter + 1,
                out,
                original_program,
              )
            _ -> {
              let new_program = list.drop(original_program, 2 * mem)
              compute_byte_code(new_program, memory, mem, out, original_program)
            }
          }
        }
        4 -> {
          let cur_b = dict.get(memory, B) |> result.unwrap(0)
          let cur_c = dict.get(memory, C) |> result.unwrap(0)

          let new_mem =
            dict.insert(memory, B, int.bitwise_exclusive_or(cur_b, cur_c))

          compute_byte_code(
            rest,
            new_mem,
            instruction_counter + 1,
            out,
            original_program,
          )
        }
        5 -> {
          let op_val = get_op_value(operand, memory)

          let new_out = list.append(out, [op_val % 8])

          compute_byte_code(
            rest,
            memory,
            instruction_counter + 1,
            new_out,
            original_program,
          )
        }
        6 -> {
          compute_byte_code(
            rest,
            adv(operand, memory, B),
            instruction_counter + 1,
            out,
            original_program,
          )
        }
        7 -> {
          compute_byte_code(
            rest,
            adv(operand, memory, C),
            instruction_counter + 1,
            out,
            original_program,
          )
        }
        _ -> todo
      }
    }
    [] -> out
    [_] -> todo
  }
}

pub fn p1(program, registers) {
  compute_byte_code(program, registers, 0, [], program)
  |> list.fold("", fn(acc, cur) { acc <> int.to_string(cur) <> "," })
  |> string.drop_end(1)
  |> io.debug()
}

pub fn main() {
  let input =
    simplifile.read("input")
    |> result.unwrap("")
    |> string.split("\n")
  let registers =
    input
    |> list.take(3)
    |> list.fold(dict.new(), fn(acc, val) {
      let #(left, right) =
        string.split_once(val, ": ") |> result.unwrap(#("", ""))
      let #(_, reg_name) =
        left |> string.split_once(" ") |> result.unwrap(#("", ""))
      let value = int.parse(right) |> result.unwrap(0)

      let reg = case reg_name {
        "A" -> A
        "B" -> B
        "C" -> C
        _ -> C
      }

      dict.insert(acc, reg, value)
    })

  let program =
    input
    |> list.drop(4)
    |> list.take(1)
    |> list.first()
    |> result.unwrap("")
    |> string.split(" ")
    |> list.filter(fn(a) { !string.contains(a, "Program") })
    |> list.first()
    |> result.unwrap("")
    |> string.split(",")
    |> list.map(fn(a) { int.parse(a) |> result.unwrap(-1) })

  let program_string =
    program
    |> list.fold("", fn(acc, cur) { acc <> int.to_string(cur) <> "," })
    |> string.drop_end(1)

  p1(program, registers)
}
