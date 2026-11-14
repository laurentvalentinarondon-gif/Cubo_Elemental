@tool
class_name MazeBuilder
extends Node3D

const MazeData = preload("res://scripts/maze_data.gd")

signal player_reached_exit

@export_category("Dimensiones")
@export var cell_size: float = 4.0
@export var wall_height: float = 3.2
@export var wall_thickness: float = 0.3
@export var include_ceiling: bool = false

@export_category("Materiales")
@export var wall_material: StandardMaterial3D
@export var floor_material: StandardMaterial3D
@export var start_material: StandardMaterial3D
@export var exit_material: StandardMaterial3D
@export var hazard_material: StandardMaterial3D

var _start_pyramid: MeshInstance3D
var _exit_pyramid: MeshInstance3D
var _hazard_nodes: Array[Node3D] = []

# Celdas sin salida donde se colocan trampas/obstáculos que restan vida
const DEAD_ENDS: Array[Vector2i] = [
	Vector2i(6, 5),
	Vector2i(11, 10),
	Vector2i(4, 12),
	Vector2i(8, 12),
	Vector2i(13, 13),
	Vector2i(3, 14)
]

func _ready() -> void:
	_setup_default_materials()
	build_maze()

func _setup_default_materials() -> void:
	if wall_material == null:
		wall_material = StandardMaterial3D.new()
		wall_material.albedo_color = Color(0.12, 0.16, 0.23) # Slate 800 (#1e293b)
		wall_material.roughness = 0.55
		wall_material.metallic = 0.05

	if floor_material == null:
		floor_material = StandardMaterial3D.new()
		floor_material.albedo_color = Color(0.85, 0.88, 0.92) # Gris claro pizarra
		floor_material.roughness = 0.4
		floor_material.uv1_scale = Vector3(15, 15, 1)

	if start_material == null:
		start_material = StandardMaterial3D.new()
		start_material.albedo_color = Color(0.06, 0.72, 0.5) # Verde esmeralda (#10b981)
		start_material.emission_enabled = true
		start_material.emission = Color(0.06, 0.72, 0.5)
		start_material.emission_energy_multiplier = 1.5

	if exit_material == null:
		exit_material = StandardMaterial3D.new()
		exit_material.albedo_color = Color(0.02, 0.65, 0.45) # Verde oscuro brillante (#059669)
		exit_material.emission_enabled = true
		exit_material.emission = Color(0.02, 0.65, 0.45)
		exit_material.emission_energy_multiplier = 2.5

	if hazard_material == null:
		hazard_material = StandardMaterial3D.new()
		hazard_material.albedo_color = Color(0.95, 0.15, 0.15) # Rojo peligro (#ef4444)
		hazard_material.emission_enabled = true
		hazard_material.emission = Color(0.95, 0.15, 0.15)
		hazard_material.emission_energy_multiplier = 2.2

func build_maze() -> void:
	for child in get_children():
		child.queue_free()
	_hazard_nodes.clear()

	_build_floor()
	_build_walls()
	_build_start_marker()
	_build_exit_portal()
	_build_hazards()

func _build_floor() -> void:
	var total_w: float = MazeData.COLS * cell_size
	var total_d: float = MazeData.ROWS * cell_size

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(total_w + 2.0, 0.4, total_d + 2.0)
	box_mesh.material = floor_material
	mesh_inst.mesh = box_mesh

	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_mesh.size
	col_shape.shape = shape

	floor_body.position = Vector3(total_w * 0.5, -0.2, total_d * 0.5)
	floor_body.add_child(mesh_inst)
	floor_body.add_child(col_shape)
	add_child(floor_body)

	if include_ceiling:
		var ceiling_body := StaticBody3D.new()
		ceiling_body.name = "Ceiling"
		var c_mesh_inst := MeshInstance3D.new()
		var c_box := BoxMesh.new()
		c_box.size = box_mesh.size
		c_box.material = wall_material
		c_mesh_inst.mesh = c_box

		var c_shape := CollisionShape3D.new()
		c_shape.shape = shape
		ceiling_body.position = Vector3(total_w * 0.5, wall_height + 0.2, total_d * 0.5)
		ceiling_body.add_child(c_mesh_inst)
		ceiling_body.add_child(c_shape)
		add_child(ceiling_body)

func _build_walls() -> void:
	var walls_node := Node3D.new()
	walls_node.name = "Walls"
	add_child(walls_node)

	for r in range(MazeData.ROWS + 1):
		for c in range(MazeData.COLS):
			if MazeData.H_WALLS[r][c] == 1:
				var wall_x: float = (c + 0.5) * cell_size
				var wall_z: float = r * cell_size
				var wall_w: float = cell_size + wall_thickness
				var wall_d: float = wall_thickness
				var wall := _create_wall_segment(Vector3(wall_x, wall_height * 0.5, wall_z), Vector3(wall_w, wall_height, wall_d))
				wall.name = "HWall_%d_%d" % [r, c]
				walls_node.add_child(wall)

	for r in range(MazeData.ROWS):
		for c in range(MazeData.COLS + 1):
			if MazeData.V_WALLS[r][c] == 1:
				var wall_x: float = c * cell_size
				var wall_z: float = (r + 0.5) * cell_size
				var wall_w: float = wall_thickness
				var wall_d: float = cell_size + wall_thickness
				var wall := _create_wall_segment(Vector3(wall_x, wall_height * 0.5, wall_z), Vector3(wall_w, wall_height, wall_d))
				wall.name = "VWall_%d_%d" % [r, c]
				walls_node.add_child(wall)

	var pillars_node := Node3D.new()
	pillars_node.name = "Pillars"
	add_child(pillars_node)
	var pillar_mesh := BoxMesh.new()
	pillar_mesh.size = Vector3(wall_thickness * 1.1, wall_height * 1.02, wall_thickness * 1.1)
	pillar_mesh.material = wall_material

	for r in range(MazeData.ROWS + 1):
		for c in range(MazeData.COLS + 1):
			var has_wall: bool = false
			if c > 0 and r <= MazeData.ROWS and MazeData.H_WALLS[r][c - 1] == 1:
				has_wall = true
			elif c < MazeData.COLS and r <= MazeData.ROWS and MazeData.H_WALLS[r][c] == 1:
				has_wall = true
			elif r > 0 and c <= MazeData.COLS and MazeData.V_WALLS[r - 1][c] == 1:
				has_wall = true
			elif r < MazeData.ROWS and c <= MazeData.COLS and MazeData.V_WALLS[r][c] == 1:
				has_wall = true

			if has_wall:
				var p_inst := MeshInstance3D.new()
				p_inst.mesh = pillar_mesh
				p_inst.position = Vector3(c * cell_size, wall_height * 0.51, r * cell_size)
				pillars_node.add_child(p_inst)

func _create_wall_segment(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = wall_material
	mesh_inst.mesh = box

	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col_shape.shape = shape

	body.add_child(mesh_inst)
	body.add_child(col_shape)
	return body

func _build_start_marker() -> void:
	var start_pos := Vector3((MazeData.START_CELL.x + 0.5) * cell_size, 0.05, (MazeData.START_CELL.y + 0.5) * cell_size)

	var marker_node := Node3D.new()
	marker_node.name = "StartMarker"
	marker_node.position = start_pos

	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = cell_size * 0.35
	base_mesh.bottom_radius = cell_size * 0.38
	base_mesh.height = 0.08
	base_mesh.material = start_material
	var base_inst := MeshInstance3D.new()
	base_inst.mesh = base_mesh
	marker_node.add_child(base_inst)

	var prism := PrismMesh.new()
	prism.size = Vector3(1.2, 1.4, 0.5)
	prism.material = start_material
	_start_pyramid = MeshInstance3D.new()
	_start_pyramid.mesh = prism
	_start_pyramid.position = Vector3(0, 1.8, 0)
	marker_node.add_child(_start_pyramid)

	var light := OmniLight3D.new()
	light.light_color = Color(0.1, 0.9, 0.5)
	light.light_energy = 1.2
	light.omni_range = 6.0
	light.position = Vector3(0, 1.5, 0)
	marker_node.add_child(light)

	add_child(marker_node)

func _build_exit_portal() -> void:
	var exit_pos := Vector3((MazeData.EXIT_CELL.x + 0.5) * cell_size, 0.05, (MazeData.EXIT_CELL.y + 0.5) * cell_size)

	var portal_node := Node3D.new()
	portal_node.name = "ExitPortal"
	portal_node.position = exit_pos

	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = cell_size * 0.45
	base_mesh.bottom_radius = cell_size * 0.48
	base_mesh.height = 0.12
	base_mesh.material = exit_material
	var base_inst := MeshInstance3D.new()
	base_inst.mesh = base_mesh
	portal_node.add_child(base_inst)

	var prism := PrismMesh.new()
	prism.size = Vector3(1.5, 1.6, 0.6)
	prism.material = exit_material
	_exit_pyramid = MeshInstance3D.new()
	_exit_pyramid.mesh = prism
	_exit_pyramid.rotation_degrees = Vector3(180, 0, 0)
	_exit_pyramid.position = Vector3(0, 2.0, 0)
	portal_node.add_child(_exit_pyramid)

	var light := OmniLight3D.new()
	light.light_color = Color(0.05, 1.0, 0.6)
	light.light_energy = 3.0
	light.omni_range = 10.0
	light.position = Vector3(0, 2.0, 0)
	portal_node.add_child(light)

	var area := Area3D.new()
	area.name = "VictoryTrigger"
	area.collision_layer = 0xFFFFFFFF
	area.collision_mask = 0xFFFFFFFF
	
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(cell_size * 0.95, wall_height * 1.2, cell_size * 0.95)
	col.shape = box_shape
	col.position = Vector3(0, wall_height * 0.5, 0)
	area.add_child(col)
	
	area.body_entered.connect(_on_victory_body_entered)
	portal_node.add_child(area)

	add_child(portal_node)

func _build_hazards() -> void:
	var hazards_parent := Node3D.new()
	hazards_parent.name = "Hazards"
	add_child(hazards_parent)

	for cell in DEAD_ENDS:
		var h_pos := Vector3((cell.x + 0.5) * cell_size, 0.9, (cell.y + 0.5) * cell_size)
		var h_node := Node3D.new()
		h_node.name = "Hazard_%d_%d" % [cell.y, cell.x]
		h_node.position = h_pos

		var mesh_inst := MeshInstance3D.new()
		var p_mesh := PrismMesh.new()
		p_mesh.size = Vector3(0.9, 1.2, 0.9)
		p_mesh.material = hazard_material
		mesh_inst.mesh = p_mesh
		h_node.add_child(mesh_inst)

		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.2, 0.2)
		light.light_energy = 2.0
		light.omni_range = 5.0
		h_node.add_child(light)

		var area := Area3D.new()
		area.name = "DamageArea"
		area.collision_layer = 0xFFFFFFFF
		area.collision_mask = 0xFFFFFFFF
		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.2
		col.shape = sphere
		area.add_child(col)

		area.body_entered.connect(func(body: Node3D):
			if body.has_method("recibir_dano"):
				body.recibir_dano(1)
		)
		h_node.add_child(area)

		hazards_parent.add_child(h_node)
		_hazard_nodes.append(h_node)

func _process(delta: float) -> void:
	var time: float = Time.get_ticks_msec() / 1000.0
	if _start_pyramid and is_instance_valid(_start_pyramid):
		_start_pyramid.rotation.y += delta * 1.2
		_start_pyramid.position.y = 1.8 + sin(time * 2.5) * 0.15

	if _exit_pyramid and is_instance_valid(_exit_pyramid):
		_exit_pyramid.rotation.y -= delta * 1.8
		_exit_pyramid.position.y = 2.0 + sin(time * 3.0) * 0.18

	for h in _hazard_nodes:
		if is_instance_valid(h):
			h.rotation.y += delta * 2.0
			h.position.y = 0.9 + sin(time * 3.5 + h.position.x) * 0.15

func _on_victory_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "Personaje" or body.name == "Player" or body.has_method("recibir_dano"):
		player_reached_exit.emit()

func get_cell_global_position(cell: Vector2i, y: float = 0.0) -> Vector3:
	return global_position + Vector3((cell.x + 0.5) * cell_size, y, (cell.y + 0.5) * cell_size)
