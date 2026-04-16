extends Node3D

var player: Player
var debug_camera: DebugCamera

var voxel_world: VoxelWorld1
var is_debug_mode = false

func _ready() -> void:
	randomize()
	
	var light = DirectionalLight3D.new()
	light.name = "LuzDireccional"
	light.rotate_x(deg_to_rad(-45))
	add_child(light)
	
	voxel_world = VoxelWorld1.new()
	voxel_world.name = "VoxelWorld"
	add_child(voxel_world)
	
	player = Player.new()
	player.name = "Player"
	player.position = voxel_world.get_spawn_position()
	add_child(player)
	
	debug_camera = DebugCamera.new()
	add_child(debug_camera)
	debug_camera.camera.current = false
	
	player.set_voxel_world_reference(voxel_world)
	voxel_world.mineral_collected.connect(player.add_to_inventory)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# SI ESC ES PRESIONADO is_debug_mode = true
	if event.is_action_pressed("Toggle_debug_camera"):
		is_debug_mode = !is_debug_mode
		
		# Si is_debug_mode es verdadero
		if is_debug_mode:
			debug_camera.global_transform = player.get_camera_transform()
			debug_camera.camera.rotation.x = player.camera.rotation.x
			debug_camera.make_current()
			player.set_active_player_controller(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			print("Modo Depuracion: ACTIVADO")
		else:
			player.make_camera_current()
			player.set_active_player_controller(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			print("Modo Depuracion: DESACTIVADO")

func get_diagnostic():
		# --- IMPRESIÓN DE DIAGNÓSTICO ---
	print("Árbol de escena del obstaculo al ser creado:")
	print_tree_pretty()
