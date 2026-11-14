class_name MiniMap
extends Control

const MazeData = preload("res://scripts/maze_data.gd")

@export var maze_node: Node3D
@export var player_node: Node3D
@export var show_solution: bool = false

var _shortest_path: Array[Vector2i] = []

func _ready() -> void:
	_shortest_path = MazeData.solve_shortest_path()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func toggle_solution() -> void:
	show_solution = not show_solution
	queue_redraw()

func _draw() -> void:
	var rect_size: Vector2 = size
	var padding: float = 8.0
	var draw_w: float = rect_size.x - padding * 2.0
	var draw_h: float = rect_size.y - padding * 2.0
	var cell_w: float = draw_w / float(MazeData.COLS)
	var cell_h: float = draw_h / float(MazeData.ROWS)

	# Fondo
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.08, 0.11, 0.16, 0.88), true)
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.3, 0.4, 0.5, 0.9), false, 2.0)

	# Camino resuelto (opcional - Tecla H)
	if show_solution and not _shortest_path.is_empty():
		for cell in _shortest_path:
			var cx: float = padding + (cell.x + 0.5) * cell_w
			var cy: float = padding + (cell.y + 0.5) * cell_h
			draw_circle(Vector2(cx, cy), cell_w * 0.25, Color(1.0, 0.85, 0.2, 0.5))

	# Dibujar Paredes Horizontales
	for r in range(MazeData.ROWS + 1):
		for c in range(MazeData.COLS):
			if MazeData.H_WALLS[r][c] == 1:
				var p1 := Vector2(padding + c * cell_w, padding + r * cell_h)
				var p2 := Vector2(padding + (c + 1) * cell_w, padding + r * cell_h)
				draw_line(p1, p2, Color(0.9, 0.95, 1.0, 0.9), 2.0)

	# Dibujar Paredes Verticales
	for r in range(MazeData.ROWS):
		for c in range(MazeData.COLS + 1):
			if MazeData.V_WALLS[r][c] == 1:
				var p1 := Vector2(padding + c * cell_w, padding + r * cell_h)
				var p2 := Vector2(padding + c * cell_w, padding + (r + 1) * cell_h)
				draw_line(p1, p2, Color(0.9, 0.95, 1.0, 0.9), 2.0)

	# Marcador Inicio (Triángulo Verde hacia Arriba)
	var s_center := Vector2(padding + (MazeData.START_CELL.x + 0.5) * cell_w, padding + (MazeData.START_CELL.y + 0.5) * cell_h)
	var s_pts: PackedVector2Array = [
		s_center + Vector2(0, -cell_h * 0.35),
		s_center + Vector2(cell_w * 0.35, cell_h * 0.35),
		s_center + Vector2(-cell_w * 0.35, cell_h * 0.35)
	]
	draw_colored_polygon(s_pts, Color(0.06, 0.85, 0.5))

	# Marcador Salida (Triángulo Verde hacia Abajo)
	var e_center := Vector2(padding + (MazeData.EXIT_CELL.x + 0.5) * cell_w, padding + (MazeData.EXIT_CELL.y + 0.5) * cell_h)
	var e_pts: PackedVector2Array = [
		e_center + Vector2(0, cell_h * 0.35),
		e_center + Vector2(cell_w * 0.35, -cell_h * 0.35),
		e_center + Vector2(-cell_w * 0.35, -cell_h * 0.35)
	]
	draw_colored_polygon(e_pts, Color(0.06, 0.85, 0.5))

	# Marcador del Jugador y Dirección
	if player_node and maze_node and is_instance_valid(player_node):
		var maze_cs: float = maze_node.cell_size if "cell_size" in maze_node else 4.0
		var p_pos_rel: Vector3 = player_node.global_position - maze_node.global_position
		var norm_x: float = clamp(p_pos_rel.x / (MazeData.COLS * maze_cs), 0.0, 1.0)
		var norm_y: float = clamp(p_pos_rel.z / (MazeData.ROWS * maze_cs), 0.0, 1.0)

		var px: float = padding + norm_x * draw_w
		var py: float = padding + norm_y * draw_h

		draw_circle(Vector2(px, py), cell_w * 0.35, Color(0.1, 0.7, 1.0, 1.0))
		draw_circle(Vector2(px, py), cell_w * 0.35, Color(1, 1, 1, 0.8), false, 1.5)

		var forward_dir: Vector3 = -player_node.transform.basis.z
		var dir_2d := Vector2(forward_dir.x, forward_dir.z).normalized()
		draw_line(Vector2(px, py), Vector2(px, py) + dir_2d * (cell_w * 0.7), Color(1.0, 1.0, 0.2), 2.0)
