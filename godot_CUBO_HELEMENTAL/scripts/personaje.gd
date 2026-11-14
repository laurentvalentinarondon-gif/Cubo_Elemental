class_name Personaje
extends CharacterBody3D

enum Estado { QUIETO, CAMINAR, CORRER, AIRE }

signal vidas_cambiadas(vidas_actuales: int, max_vidas: int)
signal murio

@export var camara: Camera3D
@export var speed_caminar: float = 3.8
@export var speed_correr: float = 7.2
@export var giro: float = 10.0
@export var fuerza_salto: float = 5.0
@export var max_vidas: int = 3

@onready var modelo: Node3D = $Modelo
@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer

var estado = Estado.QUIETO
var vidas: int = 3
var es_invulnerable: bool = false
var can_move: bool = true
var posicion_inicial: Vector3 = Vector3(2.0, 0.5, 2.0)

func _ready() -> void:
	vidas = max_vidas
	vidas_cambiadas.emit(vidas, max_vidas)
	if camara == null:
		camara = get_viewport().get_camera_3d()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Comprobar si cayó al vacío
	if global_position.y < -3.0 and vidas > 0:
		recibir_dano(1)
		if vidas > 0:
			teleport_to(posicion_inicial)
		return

	# Tecla de prueba de daño (K)
	if Input.is_action_just_pressed("test_damage") or Input.is_physical_key_pressed(KEY_K) and not es_invulnerable:
		if Input.is_key_pressed(KEY_K):
			recibir_dano(1)

	if not can_move or vidas <= 0:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		move_and_slide()
		if anim and vidas > 0:
			anim.play("idle")
		return

	# Salto
	var jump_pressed: bool = (
		Input.is_action_just_pressed("saltar") or 
		Input.is_action_just_pressed("jump") or 
		Input.is_physical_key_pressed(KEY_SPACE)
	)
	if jump_pressed and is_on_floor():
		velocity.y = fuerza_salto

	# Vector de entrada (soporta move_up/down/left/right, move_forward/backward y flechas)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var entrada := Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Rotar según la vista horizontal de la cámara
	var rot_y: float = 0.0
	if camara and is_instance_valid(camara):
		rot_y = camara.global_rotation.y
	var direction := entrada.rotated(Vector3.UP, rot_y).normalized()

	# Velocidad caminar / correr
	var is_sprinting: bool = (
		Input.is_action_pressed("correr") or 
		Input.is_action_pressed("sprint") or 
		Input.is_physical_key_pressed(KEY_SHIFT)
	)
	var speed: float = speed_correr if is_sprinting else speed_caminar

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Giro suave del modelo hacia la dirección de movimiento
	if direction.length() > 0.0:
		var angulo_objetivo: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, angulo_objetivo, giro * delta)

	move_and_slide()
	estado = elegir_estado()
	animar()

func elegir_estado() -> Estado:
	if not is_on_floor():
		return Estado.AIRE
	var plana: float = Vector2(velocity.x, velocity.z).length()
	if plana < 0.1:
		return Estado.QUIETO
	if plana > speed_caminar + 0.1:
		return Estado.CORRER
	return Estado.CAMINAR

func animar() -> void:
	if anim == null or not is_instance_valid(anim):
		return
	match estado:
		Estado.QUIETO:
			anim.play("idle")
		Estado.CAMINAR:
			anim.play("walk")
		Estado.CORRER:
			anim.play("sprint")
		Estado.AIRE:
			if velocity.y > 0:
				anim.play("jump")
			else:
				anim.play("fall")

func recibir_dano(cantidad: int = 1) -> void:
	if es_invulnerable or vidas <= 0:
		return
	vidas = max(0, vidas - cantidad)
	vidas_cambiadas.emit(vidas, max_vidas)
	
	if vidas <= 0:
		can_move = false
		if anim:
			anim.play("fall")
		murio.emit()
	else:
		_parpadear_invulnerabilidad()

func _parpadear_invulnerabilidad() -> void:
	es_invulnerable = true
	for i in range(5):
		if modelo and is_instance_valid(modelo):
			modelo.visible = false
		await get_tree().create_timer(0.12).timeout
		if modelo and is_instance_valid(modelo):
			modelo.visible = true
		await get_tree().create_timer(0.12).timeout
	es_invulnerable = false

func reiniciar(pos: Vector3) -> void:
	posicion_inicial = pos
	vidas = max_vidas
	can_move = true
	es_invulnerable = false
	global_position = pos
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	if modelo and is_instance_valid(modelo):
		modelo.visible = true
	if anim and is_instance_valid(anim):
		anim.play("idle")
	vidas_cambiadas.emit(vidas, max_vidas)

func teleport_to(new_pos: Vector3) -> void:
	global_position = new_pos
	velocity = Vector3.ZERO
