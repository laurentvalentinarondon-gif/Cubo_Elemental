class_name OverheadCamera
extends Camera3D

const MazeData = preload("res://scripts/maze_data.gd")

@export var maze_node: Node3D
@export var player_node: Node3D
@export var beacon_marker: MeshInstance3D

func _ready() -> void:
	if maze_node:
		var cs: float = maze_node.cell_size if "cell_size" in maze_node else 4.0
		var total_w: float = MazeData.COLS * cs
		var total_d: float = MazeData.ROWS * cs
		position = Vector3(total_w * 0.5, 62.0, total_d * 0.5)
		rotation_degrees = Vector3(-90, 0, 0)
		current = false

func _process(_delta: float) -> void:
	if current and beacon_marker and player_node and is_instance_valid(player_node):
		beacon_marker.visible = true
		beacon_marker.global_position = Vector3(player_node.global_position.x, 3.8, player_node.global_position.z)
	elif beacon_marker and is_instance_valid(beacon_marker):
		beacon_marker.visible = false
