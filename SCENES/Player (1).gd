# Player.gd
class_name Player
extends CharacterBody3D

# --- Sensibilidad y Movimiento ---
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.005  # Radianes por píxel de movimiento del ratón
# --- Referencias a Nodos Hijos ---
var camera: Camera3D
var raycast: RayCast3D
# --- Estado del Jugador ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mineral_count: int = 0
# VARIABLES DE HERRAMIENTA
var pickaxe_power: float = 25.0
# CREACION DEL INVENTARIO
var inventory = {
	VoxelWorld1.DIAMOND: 0,
	VoxelWorld1.RUBY: 0,
	VoxelWorld1.STONE: 0,
}
# REFERENCIA A VOXELWORLD
var voxel_world: VoxelWorld1
var shop_ui_scene: PackedScene
var shop_ui_instance: Control

# VARIABLE PARA DESACTIVAR O ACTIVAR EL CONTROL DE PALYER
var is_active: bool = true
# -----------------------------------------------------------------------------
# FUNCIONES DEL MOTOR DE GODOT
# -----------------------------------------------------------------------------

func get_camera_transform() -> Transform3D:
	return camera.global_transform

func make_camera_current():
	camera.make_current()

func _ready() -> void:
	# Esperar a que el mundo de vóxeles esté listo y obtener su referencia
	var world_nodes = get_tree().get_nodes_in_group("voxel_world_group")
	if world_nodes.size() > 0:
		set_voxel_world_reference(world_nodes[0])
	else:
		print("Error: No se encontró el nodo VoxelWorld en el grupo 'voxel_world_group'.")
	
	shop_ui_scene = preload("res://SCENES/ShopUI.tscn")
	shop_ui_instance = shop_ui_scene.instantiate()
	get_tree().get_root().add_child(shop_ui_instance)
	shop_ui_instance.set_player_reference(self)
	
	shop_ui_instance.hide()
	shop_ui_instance.shop_closed.connect(_on_shop_closed)
	shop_ui_instance.pickaxe_upgraded.connect(_on_pickaxe_upgraded)

func _init():
	# El jugador "emite" en la capa 2 (objetos dinámicos).
	set_collision_layer_value(2, true)
	# El jugador "escucha" la capa 1 (el mundo estático como el suelo).
	set_collision_mask_value(1, true)
	
	var collision_shape = CollisionShape3D.new()
#	var capsule_shape = CapsuleShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 1.8, 0.8)
	collision_shape.shape = box_shape
	add_child(collision_shape)
	
	var visual_body = MeshInstance3D.new()
	var visual_mesh = BoxMesh.new()
	visual_mesh.size = box_shape.size
	visual_body.mesh = visual_mesh
	
	var materiaL = StandardMaterial3D.new()
	materiaL.albedo_color = Color(0.0, 0.0, 1.0, 1.0)
	materiaL.backlight_enabled = true
	materiaL.backlight = Color(0,1,1)
	visual_mesh.material = materiaL
	add_child(visual_body)
	
	# --- Crear y Configurar la Cámara ---
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.8, -0.3)
	add_child(camera)
	
	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0,0,-10)
	camera.add_child(raycast)
	raycast.add_exception(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func add_to_inventory(voxel_type: int):
	if inventory.has(voxel_type):
		inventory[voxel_type] += 1
		print("Inventario actualizado: ", inventory)
	else:
		print("Intentando anhadir un tipo de mineral desconocido: ", voxel_type)

func set_voxel_world_reference(wolrd_node: VoxelWorld1):
	self.voxel_world = wolrd_node
	self.voxel_world.voxel_mined.connect(add_to_inventory)

func set_active_player_controller(active: bool):
	self.is_active = active
	# DESACTIVAR PROCESS E INPUT DE RATON
	set_physics_process(active)
	set_process_unhandled_input(active)

func _unhandled_input(event: InputEvent):
	if not is_active:
		return
	# CAPTURAR MOUSE PARA MOVER CAMARA
	if event is InputEventMouseMotion:
		# Esto hace que todo el cuerpo gire a izquierda y derecha.
		self.rotate_y(-event.relative.x * mouse_sensitivity)
		# Solo la cámara mira arriba y abajo, no todo el cuerpo.
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Usamos clamp para limitar el ángulo entre -90 y +90 grados.
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event is InputEventKey and event.keycode == KEY_G and event.is_pressed():
		if is_instance_valid(voxel_world):
			print("--- PRUEBA: Excavando bloque fijo en (8, 7, 8) ---")
			voxel_world.set_voxel(8, 7, 8, 0)
		return
	
	if event is InputEventKey and event.keycode == KEY_B and event.is_pressed():
		shop_ui_instance.show()
		set_active_player_controller(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider is VoxelWorld:
				var collision_point = raycast.get_collision_point()
				var collision_normal = raycast.get_collision_normal()
				var voxel_pos = collision_point - collision_normal * 0.1
				var voxel_x = int(floor(voxel_pos.x))
				var voxel_y = int(floor(voxel_pos.y))
				var voxel_z = int(floor(voxel_pos.z))
				if is_instance_valid(voxel_world):
					print("Intentando excavar en: (%d, %d, %d)" % [voxel_x, voxel_y, voxel_z])
					voxel_world.set_voxel(voxel_x, voxel_y, voxel_z, 0)

func _on_shop_closed():
	shop_ui_instance.hide()
	set_active_player_controller(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pickaxe_upgraded():
	pickaxe_power += 10.0
	print("Poder del pico mejorado a: ", pickaxe_power)
	
	

func _physics_process(delta: float):
	if not is_active:
		return
	# --- PASO 2: Aplicar la gravedad ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- PASO 3: Manejar el Salto ---
	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("Exit"):
		get_tree().quit()
	
	# --- PASO 4: Manejar el Movimiento (WASD) ---
	# Obtenemos el vector de dirección del input (adelante/atrás, izquierda/derecha).
	var input_dir = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# Aplicamos el movimiento.
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Si no hay input, aplicamos "fricción" para detenernos.
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# --- PASO 5: Ejecutar el movimiento ---
	move_and_slide()
