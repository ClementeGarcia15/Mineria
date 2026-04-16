class_name CreateHallazgo
extends Area3D

signal collected(item_type)

var item_type: String = "Fossil"

func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0,1.0,0.0,1)
	material.roughness = 0.5
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.25,0.25,0.25)
	mesh_instance.mesh = box_mesh
	mesh_instance.name = "Fossil"
	mesh_instance.material_override = material 
	add_child(mesh_instance)
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision_shape.shape = box_shape
	add_child(collision_shape)
	
	var point_light = OmniLight3D.new()
	point_light.light_color = Color(0, 1, 0)
	point_light.light_energy = 0.5
	add_child(point_light)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	set_collision_layer_value(3, true)

func _on_body_entered(body):
	if body is Player:
		body.set_collectible_target(self)
		print("Jugador cerca de un fosil")

func _on_body_exited(body):
	if body is Player:
		body.set_collectible_target(null)
		print("Jugador se alejo del fosil")

func do_collect():
	emit_signal("collected", item_type)
	print("Fosil recolectado!")
	queue_free()
