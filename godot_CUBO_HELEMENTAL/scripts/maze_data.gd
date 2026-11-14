class_name MazeData
extends RefCounted

## Datos exactos extraídos del laberinto 15x15 original
const ROWS: int = 15
const COLS: int = 15
const START_CELL: Vector2i = Vector2i(0, 0)
const EXIT_CELL: Vector2i = Vector2i(14, 14)

# Paredes horizontales: 16 filas (0..15), cada una con 15 segmentos (0..14)
# 1 = Pared sólida, 0 = Pasaje libre
const H_WALLS: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # r=0 (Borde superior)
	[0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0], # r=1
	[0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0], # r=2
	[1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0], # r=3
	[0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0], # r=4
	[0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], # r=5
	[0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0], # r=6
	[0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0], # r=7
	[0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1], # r=8
	[0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], # r=9
	[0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0], # r=10
	[0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0], # r=11
	[0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0], # r=12
	[0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0], # r=13
	[0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0], # r=14
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]  # r=15 (Borde inferior)
]

# Paredes verticales: 15 filas (0..14), cada una con 16 segmentos (0..15)
# 1 = Pared sólida, 0 = Pasaje libre
const V_WALLS: Array = [
	[1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1], # r=0
	[1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1], # r=1
	[1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1], # r=2
	[1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1], # r=3
	[1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1], # r=4
	[1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1], # r=5
	[1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1], # r=6
	[1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1], # r=7
	[1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1], # r=8
	[1, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1], # r=9
	[1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1], # r=10
	[1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1], # r=11
	[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1], # r=12
	[1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1], # r=13
	[1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1]  # r=14
]

## Resuelve el camino más corto mediante BFS desde start hasta exit
static func solve_shortest_path() -> Array[Vector2i]:
	var queue: Array[Vector2i] = [START_CELL]
	var visited: Dictionary = {START_CELL: null}

	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		if curr == EXIT_CELL:
			break

		var r: int = curr.y
		var c: int = curr.x

		# Vecino Norte (r - 1, c)
		if r > 0 and H_WALLS[r][c] == 0:
			var nxt: Vector2i = Vector2i(c, r - 1)
			if not visited.has(nxt):
				visited[nxt] = curr
				queue.push_back(nxt)

		# Vecino Sur (r + 1, c)
		if r < ROWS - 1 and H_WALLS[r + 1][c] == 0:
			var nxt: Vector2i = Vector2i(c, r + 1)
			if not visited.has(nxt):
				visited[nxt] = curr
				queue.push_back(nxt)

		# Vecino Oeste (r, c - 1)
		if c > 0 and V_WALLS[r][c] == 0:
			var nxt: Vector2i = Vector2i(c - 1, r)
			if not visited.has(nxt):
				visited[nxt] = curr
				queue.push_back(nxt)

		# Vecino Este (r, c + 1)
		if c < COLS - 1 and V_WALLS[r][c + 1] == 0:
			var nxt: Vector2i = Vector2i(c + 1, r)
			if not visited.has(nxt):
				visited[nxt] = curr
				queue.push_back(nxt)

	var path: Array[Vector2i] = []
	if visited.has(EXIT_CELL):
		var curr_node = EXIT_CELL
		while curr_node != null:
			path.append(curr_node)
			curr_node = visited[curr_node]
		path.reverse()

	return path
