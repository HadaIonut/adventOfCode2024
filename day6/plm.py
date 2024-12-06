
import itertools as it

class D:
    LEFT = 0
    UP = 1
    RIGHT = 2
    DOWN = 3
directions = "<^>v"
dx = [-1, 0, 1, 0]
dy = [0, -1, 0, 1]

def parse_lines(filename):
    with open(filename, "r") as f:
        lines = f.readlines()
    return [l.rstrip("\n") for l in lines if l.strip()]

def parse_blocks(lines):
    blocks_by_row = {}
    for row, l in enumerate(lines):
        blocks_by_row[row] = set()
        for col, c in enumerate(l):
            if c == "#":
                blocks_by_row[row].add(col)
            elif c in directions:
                guard = (row, col)
    
    blocks_by_col = {col: set() for col in range(len(lines[0]))}
    for row in range(len(lines)):
        for col in blocks_by_row[row]:
            blocks_by_col[col].add(row)
    
    return blocks_by_row, blocks_by_col, guard

def patrol(blocks_by_row, blocks_by_col, guard, direction, checkloop=False):
    exited = False
    visited = set()
    decisions = set()
    row, col = guard

    while True:
        new_row, new_col = row, col
        try:
            if direction == D.UP:
                new_row = max(b for b in blocks_by_col[col] if b < row) + 1
            elif direction == D.DOWN:
                new_row = min(b for b in blocks_by_col[col] if b > row) - 1
            elif direction == D.LEFT:
                new_col = max(b for b in blocks_by_row[row] if b < col) + 1
            elif direction == D.RIGHT:
                new_col = min(b for b in blocks_by_row[row] if b > col) - 1
        except ValueError: # left the maze
            if direction == D.UP:
                new_row = -1
            elif direction == D.DOWN:
                new_row = len(blocks_by_row)
            elif direction == D.LEFT:
                new_col = -1
            elif direction == D.RIGHT:
                new_col = len(blocks_by_col)
            exited = True
        
        # Walk to the next obstacle
        if dx[direction]:
            rx = range(col, new_col, dx[direction])
            ry = it.repeat(row)
        elif dy[direction]:
            rx = it.repeat(col)
            ry = range(row, new_row, dy[direction])
        for nx, ny in zip(rx, ry):
            visited.add((ny, nx))

        if checkloop: # Part 2
            if exited:
                return False
            elif (row, col, direction) in decisions:
                return True
            else:
                decisions.add((row, col, direction))
        elif exited:
            return visited

        # Carry on
        row, col = new_row, new_col
        direction = (direction + 1) % 4

def day06_part1(filename):
    lines = parse_lines(filename)
    blocks_by_row, blocks_by_col, guard = parse_blocks(lines)

    direction = directions.index(lines[guard[0]][guard[1]])
    visited = patrol(blocks_by_row, blocks_by_col, guard, direction)
    return len(visited)

def day06_part2(filename):
    lines = parse_lines(filename)
    blocks_by_row, blocks_by_col, guard = parse_blocks(lines)

    direction = directions.index(lines[guard[0]][guard[1]])
    visited = patrol(blocks_by_row, blocks_by_col, guard, direction)

    nloops = 0
    for row, col in visited:
        blocks_by_row[row].add(col)
        blocks_by_col[col].add(row)
        if patrol(blocks_by_row, blocks_by_col, guard, direction, checkloop=True):
            nloops += 1
        blocks_by_row[row].remove(col)
        blocks_by_col[col].remove(row)
    return nloops

if __name__ == "__main__":
    print("Part 2", day06_part2("./input"))

