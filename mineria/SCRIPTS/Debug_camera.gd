# DebugCamera.gd
class_name DebugCamera
extends Node3D

var speed = 10.0
var mouse_sensitivity = 0.005

var camera: Camera3D

func _init() -> void:
	camera = Camera3D.new()
	add_child(camera)

func _unhandled_input(event: InputEvent):
	if !camera.is_current():
		return
		
	# Rotación con el ratón (solo si la cámara está activa)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			self.rotate_y(-event.relative.x * mouse_sensitivity)
			
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			
			# Limitar la rotación vertical para no dar la vuelta
			self.rotation.x = clamp(self.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(delta):
	# Movimiento (solo si la cámara está activa)
	if !camera.is_current():
		return

	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("UP"): # W
		direction -= self.global_transform.basis.z
	if Input.is_action_pressed("DOWN"): # S
		direction += self.global_transform.basis.z
	if Input.is_action_pressed("LEFT"): # A
		direction -= self.global_transform.basis.x
	if Input.is_action_pressed("RIGHT"): # D
		direction += self.global_transform.basis.x
	
	if Input.is_action_pressed("JUMP"): # Espacio (Subir)
		direction += Vector3.UP
	if Input.is_action_pressed("camera_down"): # Tab (Bajar)
		direction += Vector3.DOWN
		
	# Aplicar movimiento
	self.global_position += direction.normalized() * speed * delta

func make_current():
	camera.make_current()

func get_camera_transform() -> Transform3D:
	return camera.global_transform
