class_name MainGame
extends Node3D

const MazeData = preload("res://scripts/maze_data.gd")

@onready var maze: Node3D = $Maze
@onready var player: CharacterBody3D = $Personaje
@onready var overhead_cam: Camera3D = $OverheadCamera
@onready var hud: CanvasLayer = $HUD
@onready var player_beacon: MeshInstance3D = $PlayerBeacon

var _is_overhead_mode: bool = false
var _game_won: bool = false

func _ready() -> void:
	if maze and maze.has_signal("player_reached_exit"):
		maze.player_reached_exit.connect(_on_player_reached_exit)

	if player:
		if player.has_signal("vidas_cambiadas"):
			player.vidas_cambiadas.connect(_on_player_vidas_cambiadas)
		if player.has_signal("murio"):
			player.murio.connect(_on_player_died)

	if hud:
		if hud.has_signal("restart_requested"):
			hud.restart_requested.connect(restart_game)
		var minimap_node = hud.get_node_or_null("MinimapContainer/MiniMap")
		if minimap_node:
			minimap_node.maze_node = maze
			minimap_node.player_node = player

	if overhead_cam:
		overhead_cam.maze_node = maze
		overhead_cam.player_node = player
		overhead_cam.beacon_marker = player_beacon

	restart_game()

func restart_game() -> void:
	_game_won = false
	if maze and player:
		var start_pos: Vector3 = maze.get_cell_global_position(MazeData.START_CELL, 0.5)
		if player.has_method("reiniciar"):
			player.reiniciar(start_pos)
		else:
			player.global_position = start_pos
			player.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_set_overhead_mode(false)
	if hud:
		if hud.has_method("reset_timer"):
			hud.reset_timer()
		if player and "vidas" in player and hud.has_method("update_lives"):
			hud.update_lives(player.vidas, player.max_vidas)

func _physics_process(_delta: float) -> void:
	# Verificación redundante infalible de meta por distancia matemática
	if not _game_won and player and is_instance_valid(player) and maze:
		var exit_pos: Vector3 = maze.get_cell_global_position(MazeData.EXIT_CELL, 0.0)
		var p2d := Vector2(player.global_position.x, player.global_position.z)
		var e2d := Vector2(exit_pos.x, exit_pos.z)
		var cs: float = maze.cell_size if "cell_size" in maze else 4.0
		if p2d.distance_to(e2d) < (cs * 0.48):
			_on_player_reached_exit()

func _unhandled_input(event: InputEvent) -> void:
	# Alternar cámara primera persona / aérea (C o Tab)
	if event.is_action_pressed("toggle_camera") or (event is InputEventKey and event.pressed and event.keycode == KEY_C):
		toggle_camera_mode()

	# Alternar minimapa (M)
	if event.is_action_pressed("toggle_map") or (event is InputEventKey and event.pressed and event.keycode == KEY_M):
		if hud and hud.has_method("toggle_minimap"):
			hud.toggle_minimap()

	# Mostrar/ocultar camino resuelto en minimapa (H)
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		if hud and hud.has_method("toggle_solution"):
			hud.toggle_solution()

	# Reiniciar partida (R)
	if event.is_action_pressed("restart") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		restart_game()

func toggle_camera_mode() -> void:
	_set_overhead_mode(not _is_overhead_mode)

func _set_overhead_mode(overhead: bool) -> void:
	_is_overhead_mode = overhead
	if overhead_cam and player:
		overhead_cam.current = _is_overhead_mode
		var p_cam: Camera3D = player.get_node_or_null("SpringArm3D/Camera3D")
		if p_cam:
			p_cam.current = not _is_overhead_mode

	var spring_arm = player.get_node_or_null("SpringArm3D")
	if spring_arm and "activo" in spring_arm:
		spring_arm.activo = not _is_overhead_mode

	if _is_overhead_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if "can_move" in player:
			player.can_move = false
		if player_beacon:
			player_beacon.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if "can_move" in player:
			player.can_move = true
		if player_beacon:
			player_beacon.visible = false

func _on_player_vidas_cambiadas(vidas_actuales: int, max_v: int) -> void:
	if hud and hud.has_method("update_lives"):
		hud.update_lives(vidas_actuales, max_v)

func _on_player_died() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()

func _on_player_reached_exit() -> void:
	if _game_won:
		return
	_game_won = true
	print("[MainGame] 🎉 ¡VICTORIA! El jugador ha alcanzado la meta.")
	if player and "can_move" in player:
		player.can_move = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud and hud.has_method("show_victory"):
		hud.show_victory()
