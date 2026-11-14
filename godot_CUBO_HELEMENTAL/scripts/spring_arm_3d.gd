extends SpringArm3D

@export var objetivo: Node3D                # El personaje al que sigue
@export var sensibilidad: float = 0.003
@export var suavizado: float = 14.0         # Más alto = cámara más pegada
@export var altura: float = 1.4             # Apunta a la cabeza/torso
var activo: bool = true

func _ready() -> void:
	if objetivo == null:
		objetivo = get_parent() as Node3D
	top_level = true
	if objetivo is CollisionObject3D:
		add_excluded_object(objetivo.get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(evento: InputEvent) -> void:
	if not activo:
		return
	if evento.is_action_pressed("ui_cancel") or (evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= evento.relative.x * sensibilidad
		rotation.x -= evento.relative.y * sensibilidad
		rotation.x = clamp(rotation.x, deg_to_rad(-55.0), deg_to_rad(20.0))

func _physics_process(delta: float) -> void:
	if objetivo == null or not is_instance_valid(objetivo):
		return
	var destino: Vector3 = objetivo.global_position + Vector3(0.0, altura, 0.0)
	global_position = global_position.lerp(destino, delta * suavizado)
