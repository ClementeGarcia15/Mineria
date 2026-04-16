class_name VoxelWorld
extends StaticBody3D 

#var noise: FastNoiseLite

const AIR = 0
const DIRT = 1
const STONE = 2
const DIAMOND = 3
const RUBY = 4

const VOXEL_COLORS = {
	DIRT: Color.SADDLE_BROWN,
	STONE: Color.SLATE_GRAY,
	DIAMOND: Color.DEEP_SKY_BLUE,
	RUBY: Color.CRIMSON,
}

const CHUNK_SIZE_X = 16
const CHUNK_SIZE_Y = 16
const CHUNK_SIZE_Z = 16

# SUB CHUKS DEL MUNDO
var SUB_CHUNK_SIZE = 8.0
var chunk_nodes: Dictionary = {}

# --- TABLAS DE BÚSQUEDA PARA MARCHING CUBES ---
# edge_table nos dice qué vértices conecta cada una de las 12 aristas del cubo.
const edge_table = [
	[0, 1], [1, 2], [2, 3], [3, 0],
	[4, 5], [5, 6], [6, 7], [7, 4],
	[0, 4], [1, 5], [2, 6], [3, 7]
]
# triangulation_table nos dice, para cada uno de los 256 casos, qué aristas
# contienen los vértices de los triángulos que debemos dibujar.
const triangulation_table = [
	[],[0, 8, 3], [0, 1, 9], [1, 8, 3, 9, 8, 1],[1, 2, 10],[0, 8, 3, 1, 2, 10],
	[9, 2, 10, 0, 2, 9],[2, 8, 3, 2, 10, 8, 10, 9, 8],
	[3, 11, 2],[0, 11, 2, 8, 11, 0],[1, 9, 0, 2, 3, 11],[1, 11, 2, 1, 9, 11, 9, 8, 11],
	[3, 10, 1, 11, 10, 3],[0, 10, 1, 0, 8, 10, 8, 11, 10],[3, 9, 0, 3, 11, 9, 11, 10, 9],
	[9, 8, 10, 10, 8, 11],[4, 7, 8],[4, 3, 0, 7, 3, 4],[0, 1, 9, 8, 4, 7],[4, 1, 9, 4, 7, 1, 7, 3, 1],
	[1, 2, 10, 8, 4, 7],[3, 4, 7, 3, 0, 4, 1, 2, 10],[9, 2, 10, 9, 0, 2, 8, 4, 7],
	[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],[8, 4, 7, 3, 11, 2],[11, 4, 7, 11, 2, 4, 2, 0, 4],
	[9, 0, 1, 8, 4, 7, 2, 3, 11],[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],[3, 10, 1, 3, 11, 10, 7, 8, 4],
	[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
	[4, 7, 11, 4, 11, 9, 9, 11, 10],[9, 5, 4],[9, 5, 4, 0, 8, 3],[0, 5, 4, 1, 5, 0],
	[8, 5, 4, 8, 3, 5, 3, 1, 5],[1, 2, 10, 9, 5, 4],[3, 0, 8, 1, 2, 10, 4, 9, 5],
	[5, 2, 10, 5, 4, 2, 4, 0, 2],[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],[9, 5, 4, 2, 3, 11],
	[0, 11, 2, 0, 8, 11, 4, 9, 5],[0, 5, 4, 0, 1, 5, 2, 3, 11],[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
	[10, 3, 11, 10, 1, 3, 9, 5, 4],[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
	[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],[5, 4, 8, 5, 8, 10, 10, 8, 11],[9, 7, 8, 5, 7, 9],
	[9, 3, 0, 9, 5, 3, 5, 7, 3],[0, 7, 8, 0, 1, 7, 1, 5, 7],[1, 5, 3, 3, 5, 7],[9, 7, 8, 9, 5, 7, 10, 1, 2],
	[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],[2, 10, 5, 2, 5, 3, 3, 5, 7],
	[7, 9, 5, 7, 8, 9, 3, 11, 2],[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
	[11, 2, 1, 11, 1, 7, 7, 1, 5],[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
	[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
	[11, 10, 5, 7, 11, 5],[10, 6, 5],[0, 8, 3, 5, 10, 6],[9, 0, 1, 5, 10, 6],[1, 8, 3, 1, 9, 8, 5, 10, 6],
	[1, 6, 5, 2, 6, 1],[1, 6, 5, 1, 2, 6, 3, 0, 8],[9, 6, 5, 9, 0, 6, 0, 2, 6],
	[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],[2, 3, 11, 10, 6, 5],[11, 0, 8, 11, 2, 0, 10, 6, 5],
	[0, 1, 9, 2, 3, 11, 5, 10, 6],[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],[6, 3, 11, 6, 5, 3, 5, 1, 3],
	[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
	[6, 5, 9, 6, 9, 11, 11, 9, 8],[5, 10, 6, 4, 7, 8],[4, 3, 0, 4, 7, 3, 6, 5, 10],
	[1, 9, 0, 5, 10, 6, 8, 4, 7],[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],[6, 1, 2, 6, 5, 1, 4, 7, 8],
	[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
	[7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9],[3, 11, 2, 7, 8, 4, 10, 6, 5],
	[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
	[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
	[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
	[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],[10, 4, 9, 6, 4, 10],[4, 10, 6, 4, 9, 10, 0, 8, 3],
	[10, 0, 1, 10, 6, 0, 6, 4, 0],[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],[1, 4, 9, 1, 2, 4, 2, 6, 4],
	[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],[0, 2, 4, 4, 2, 6],[8, 3, 2, 8, 2, 4, 4, 2, 6],
	[10, 4, 9, 10, 6, 4, 11, 2, 3],[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
	[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
	[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
	[3, 11, 6, 3, 6, 0, 0, 6, 4],[6, 4, 8, 11, 6, 8],[7, 10, 6, 7, 8, 10, 8, 9, 10],
	[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
	[10, 6, 7, 10, 7, 1, 1, 7, 3],[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
	[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],[7, 8, 0, 7, 0, 6, 6, 0, 2],[7, 3, 2, 6, 7, 2],
	[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
	[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
	[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],[0, 9, 1, 11, 6, 7],
	[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],[7, 11, 6],[7, 6, 11],[3, 0, 8, 11, 7, 6],[0, 1, 9, 11, 7, 6],
	[8, 1, 9, 8, 3, 1, 11, 7, 6],[10, 1, 2, 6, 11, 7],[1, 2, 10, 3, 0, 8, 6, 11, 7],
	[2, 9, 0, 2, 10, 9, 6, 11, 7],[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],[7, 2, 3, 6, 2, 7],
	[7, 0, 8, 7, 6, 0, 6, 2, 0],[2, 7, 6, 2, 3, 7, 0, 1, 9],[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
	[10, 7, 6, 10, 1, 7, 1, 3, 7],[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
	[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],[7, 6, 10, 7, 10, 8, 8, 10, 9],[6, 8, 4, 11, 8, 6],
	[3, 6, 11, 3, 0, 6, 0, 4, 6],[8, 6, 11, 8, 4, 6, 9, 0, 1],[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
	[6, 8, 4, 6, 11, 8, 2, 10, 1],[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
	[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
	[8, 2, 3, 8, 4, 2, 4, 6, 2],[0, 4, 2, 4, 6, 2],[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
	[1, 9, 4, 1, 4, 2, 2, 4, 6],[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],[10, 1, 0, 10, 0, 6, 6, 0, 4],
	[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],[10, 9, 4, 6, 10, 4],[4, 9, 5, 7, 6, 11],
	[0, 8, 3, 4, 9, 5, 11, 7, 6],[5, 0, 1, 5, 4, 0, 7, 6, 11],[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
	[9, 5, 4, 10, 1, 2, 7, 6, 11],[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
	[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
	[7, 2, 3, 7, 6, 2, 5, 4, 9],[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
	[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
	[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
	[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],[6, 9, 5, 6, 11, 9, 11, 8, 9],
	[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
	[6, 11, 3, 6, 3, 5, 5, 3, 1],[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
	[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
	[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],[9, 5, 6, 9, 6, 0, 0, 6, 2],
	[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],[1, 5, 6, 2, 1, 6],
	[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
	[0, 3, 8, 5, 6, 10],[10, 5, 6],[11, 5, 10, 7, 5, 11],[11, 5, 10, 11, 7, 5, 8, 3, 0],
	[5, 11, 7, 5, 10, 11, 1, 9, 0],[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],[11, 1, 2, 11, 7, 1, 7, 5, 1],
	[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
	[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],[2, 5, 10, 2, 3, 5, 3, 7, 5],
	[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
	[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],[1, 3, 5, 3, 7, 5],[0, 8, 7, 0, 7, 1, 1, 7, 5],
	[9, 0, 3, 9, 3, 5, 5, 3, 7],[9, 8, 7, 5, 9, 7],[5, 8, 4, 5, 10, 8, 10, 11, 8],
	[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
	[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
	[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
	[9, 4, 5, 2, 11, 3],[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],[5, 10, 2, 5, 2, 4, 4, 2, 0],
	[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
	[8, 4, 5, 8, 5, 3, 3, 5, 1],[0, 4, 5, 1, 0, 5],[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],[9, 4, 5],
	[4, 11, 7, 4, 9, 11, 9, 10, 11],[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
	[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],[3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4],
	[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
	[11, 7, 4, 11, 4, 2, 2, 4, 0],[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
	[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
	[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],[1, 10, 2, 8, 7, 4],[4, 9, 1, 4, 1, 7, 7, 1, 3],
	[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],[4, 0, 3, 7, 4, 3],[4, 8, 7],[9, 10, 8, 10, 11, 8],
	[3, 0, 9, 3, 9, 11, 11, 9, 10],[0, 1, 10, 0, 10, 8, 8, 10, 11],[3, 1, 10, 11, 3, 10],
	[1, 2, 11, 1, 11, 9, 9, 11, 8],[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],[0, 2, 11, 8, 0, 11],
	[3, 2, 11],[2, 3, 8, 2, 8, 10, 10, 8, 9],[9, 10, 2, 0, 9, 2],[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
	[1, 10, 2],[1, 3, 8, 9, 1, 8],[0, 9, 1],[0, 3, 8],[]
]

var world_data: PackedByteArray = PackedByteArray()
var voxel_health: Dictionary = {}
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

@warning_ignore("unused_signal")
signal mineral_collected(voxel_type: int)
signal voxel_mined(voxel_type: int)

const hallazgo = preload("res://SCRIPTS/hallazgos.gd")

func _init() -> void:
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	
	mesh_instance = MeshInstance3D.new()
	
	var materialVoxel = StandardMaterial3D.new()
	materialVoxel.vertex_color_use_as_albedo = true
	materialVoxel.roughness = 1.0
	mesh_instance.material_overlay = materialVoxel
	add_child(mesh_instance)
	
	collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	world_data.resize(CHUNK_SIZE_X * CHUNK_SIZE_Y * CHUNK_SIZE_Z)

func _ready() -> void:
	_populate_world_data()
	
	# ¡MODIFICADO! Generar todos los chunks al inicio.
	for cz in range(CHUNK_SIZE_Z / SUB_CHUNK_SIZE):
		for cy in range(CHUNK_SIZE_Y / SUB_CHUNK_SIZE):
			for cx in range(CHUNK_SIZE_X / SUB_CHUNK_SIZE):
				var chunk_pos = Vector3i(cx, cy, cz)
				generate_mesh(chunk_pos)

func _get_voxel_index(x: int,y: int, z: int) -> int:
	return y * CHUNK_SIZE_X * CHUNK_SIZE_Z + z * CHUNK_SIZE_X + x

func get_voxel(x: int,y: int, z: int) -> int:
	if x < 0 or x >= CHUNK_SIZE_X or y < 0 or y >= CHUNK_SIZE_Y or z < 0 or z>= CHUNK_SIZE_Z:
		return 0
	return world_data[_get_voxel_index(x,y,z)]

func get_spawn_position() -> Vector3:
	var spawn_x = CHUNK_SIZE_X / 2.0
	var spawn_z = CHUNK_SIZE_Z / 2.0
	
	for y in range(CHUNK_SIZE_Y -1, -1, -1):
		var current_voxel = get_voxel(spawn_x, y, spawn_z)
		var voxel_below = get_voxel(spawn_x, y - 1, spawn_z)
		
		if current_voxel == AIR and voxel_below != AIR:
			return Vector3(spawn_x, y + 1.5, spawn_z)
	
	return Vector3(spawn_x, CHUNK_SIZE_Y + 1, spawn_z)

# Rellena el array con un terreno simple (suelo plano).
func _populate_world_data():
	world_data = []
	world_data.resize(CHUNK_SIZE_X * CHUNK_SIZE_Y * CHUNK_SIZE_Z)
	
	for y in range(CHUNK_SIZE_Y):
		for z in range(CHUNK_SIZE_Z):
			for x in range(CHUNK_SIZE_X):
				var index = _get_voxel_index(x, y, z)
				
				if y > 8:
					world_data[index] = AIR 
				elif y > 6:
					world_data[index] = DIRT
				elif y > 4:
					world_data[index] = STONE
				elif y > 2:
					world_data[index] = RUBY
				else:
					world_data[index] = DIAMOND
	print("Mundo poblado con capas de diferentes materiales.")
	
	var num_hallazgos = 50
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	print("Enterrando %d hallazgos..." % num_hallazgos)
	for i in range(num_hallazgos):
		var hallazgo_x = rng.randi_range(0, CHUNK_SIZE_X)
		var hallazgo_y = rng.randi_range(0, 5)
		var hallazgo_z = rng.randi_range(0, CHUNK_SIZE_Z)
		
		var hallazgo_pos = Vector3(hallazgo_x, hallazgo_y, hallazgo_z)
		
		var hallazgo_instance = CreateHallazgo.new()
		hallazgo_instance.position = hallazgo_pos
		
		get_parent().add_child(hallazgo_instance)
	print("%d fósiles han sido enterrados en el mundo." % num_hallazgos)

func set_voxel(x: int, y: int, z: int, type: int):
	# 1. ¿Está la coordenada fuera de los límites?
	if x < 0 or x >= CHUNK_SIZE_X or y < 0 or y >= CHUNK_SIZE_Y or z < 0 or z >= CHUNK_SIZE_Z:
		print("Error: Intento de excavar fuera de los límites.")
		return
	var index = _get_voxel_index(x, y, z)
	if world_data[index] == type:
		print("Info: El vóxel ya es del tipo deseado. No se hace nada.")
		return
		
	# 3. Si todo está bien, modificamos y regeneramos.
	print("¡Éxito! Modificando vóxel en (%d, %d, %d) y regenerando." % [x, y, z])
	world_data[index] = type
	
	# --- SECCIÓN DE ACTUALIZACIÓN DE CHUNKS (LA VERSIÓN FINAL Y CORRECTA) ---
	var chunks_to_update: Dictionary = {}
	
	for cz_offset in [-1, 0]:
		for cy_offset in [-1, 0]:
			for cx_offset in [-1, 0]:
				var check_x = x + cx_offset
				var check_y = y + cy_offset
				var check_z = z + cz_offset
				
				var chunk_pos = Vector3i(
					check_x / SUB_CHUNK_SIZE,
					check_y / SUB_CHUNK_SIZE,
					check_z / SUB_CHUNK_SIZE
				)
				chunks_to_update[chunk_pos] = true

	# Lógica de limpieza de huérfanos (tu código es correcto)
	if type == AIR:
		var neighbor_offsets = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
		for offset in neighbor_offsets:
			var neighbor_pos = Vector3i(x, y, z) + offset
			if check_and_remove_if_isolated(neighbor_pos.x, neighbor_pos.y, neighbor_pos.z):
				# Si se elimina un huérfano, también debemos actualizar su chunk y los que lo rodean.
				for cz_offset in [-1, 0]:
					for cy_offset in [-1, 0]:
						for cx_offset in [-1, 0]:
							var check_x = neighbor_pos.x + cx_offset
							var check_y = neighbor_pos.y + cy_offset
							var check_z = neighbor_pos.z + cz_offset
							var chunk_pos = Vector3i(check_x / SUB_CHUNK_SIZE, check_y / SUB_CHUNK_SIZE, check_z / SUB_CHUNK_SIZE)
							chunks_to_update[chunk_pos] = true
							
	# 4. Regenerar todos los chunks afectados, sin duplicados.
	for chunk_pos in chunks_to_update:
		# Una última comprobación para no intentar generar chunks fuera del mundo
		if chunk_pos.x >= 0 and chunk_pos.x < CHUNK_SIZE_X / SUB_CHUNK_SIZE and \
		chunk_pos.y >= 0 and chunk_pos.y < CHUNK_SIZE_Y / SUB_CHUNK_SIZE and \
		chunk_pos.z >= 0 and chunk_pos.z < CHUNK_SIZE_Z / SUB_CHUNK_SIZE:
			print("CHUNK POS: ", chunk_pos)
			generate_mesh(chunk_pos)

func generate_mesh(chunk_pos: Vector3i):
	# Si el chunk no existe en nuestro diccionario, lo creamos.
	if not chunk_nodes.has(chunk_pos):
		var new_mesh_instance = MeshInstance3D.new()
		var materialVoxel = StandardMaterial3D.new()
		materialVoxel.vertex_color_use_as_albedo = true
		materialVoxel.roughness = 1.0
		new_mesh_instance.material_overlay = materialVoxel
		
		var new_collision_shape = CollisionShape3D.new()
		
		add_child(new_mesh_instance)
		add_child(new_collision_shape)
		
		chunk_nodes[chunk_pos] = {
			"mesh_instance": new_mesh_instance,
			"collision_shape": new_collision_shape
		}
	#
	## Usaremos un SurfaceTool para construir la malla. Es más fácil que manejar arrays crudos.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Definimos las 6 caras de un cubo. Cada cara tiene 4 vértices.
	# El orden es importante para que la cara "mire" hacia afuera.
	var face_vertices = [
		# Cara -Y (Abajo)
		[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
		# Cara +Y (Arriba)
		[Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)],
		# Cara -Z (Atrás)
		[Vector3(1, 0, 0), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0)],
		# Cara +Z (Adelante)
		[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)],
		# Cara -X (Izquierda)
		[Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)],
		# Cara +X (Derecha)
		[Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1)]
	]
	
	# Direcciones para comprobar los vecinos de cada cara.
	var face_normals = [
		Vector3i.DOWN, # Abajo
		Vector3i.UP,  # Arriba
		Vector3i.BACK, # Atrás
		Vector3i.FORWARD,  # Adelante
		Vector3i.LEFT, # Izquierda
		Vector3i.RIGHT   # Derecha
	]
	
	var start_x = chunk_pos.x * SUB_CHUNK_SIZE
	var start_y = chunk_pos.y * SUB_CHUNK_SIZE 
	var start_z = chunk_pos.z * SUB_CHUNK_SIZE

	var end_x = chunk_pos.x + SUB_CHUNK_SIZE
	var end_y = chunk_pos.y + SUB_CHUNK_SIZE 
	var end_z = chunk_pos.z + SUB_CHUNK_SIZE

	# Recorremos cada vóxel del chunk
	for y in range(start_y, end_y):
		for z in range(start_z, end_z):
			for x in range(start_x, end_x):
				var voxel_type = get_voxel(x, y, z)
				
				# Si el vóxel es aire, no hay nada que dibujar.
				if voxel_type == AIR:
					continue
				
				# Obtenemos el color para este tipo de vóxel.
				var color = VOXEL_COLORS.get(voxel_type, Color.MAGENTA) # Magenta si hay error
				st.set_color(color)

				# Comprobamos las 6 caras del vóxel actual.
				for i in range(6):
					var neighbor_pos = Vector3i(x, y, z) + face_normals[i]
					var neighbor_type = get_voxel(neighbor_pos.x, neighbor_pos.y, neighbor_pos.z)
					
					# Si el vecino es aire, esta cara es visible y debemos dibujarla.
					if neighbor_type == AIR:
						var v0 = face_vertices[i][0] + Vector3(x, y, z)
						var v1 = face_vertices[i][1] + Vector3(x, y, z)
						var v2 = face_vertices[i][2] + Vector3(x, y, z)
						var v3 = face_vertices[i][3] + Vector3(x, y, z)
						
						# Añadimos los dos triángulos que forman la cara cuadrada.
						st.add_vertex(v2)
						st.add_vertex(v1)
						st.add_vertex(v0)
						
						st.add_vertex(v3)
						st.add_vertex(v2)
						st.add_vertex(v0)
						
						
	# Generamos las normales para que la iluminación funcione correctamente.
	st.generate_normals()
	
	var mesh_resource = st.commit()
	
	# Si no se generaron vértices, salimos.
	if mesh_resource.get_surface_count() == 0:
		mesh_instance.mesh = null
		if collision_shape and collision_shape.shape:
			collision_shape.shape = null
		return
	
	print(mesh_resource.ARRAY_INDEX)
	var nodes = chunk_nodes[chunk_pos]
	nodes["mesh_instance"].mesh = mesh_resource
	# Creamos la colisión. Para mallas de vóxeles, create_trimesh_shape() es perfecto.
	nodes["collision_shape"].shape = mesh_resource.create_trimesh_shape()

func check_and_remove_if_isolated(x: int, y: int, z: int) -> bool:
	# No procesar vóxeles fuera de los límites o que ya son de aire.
	if x < 1 or x >= CHUNK_SIZE_X - 1 or y < 1 or y >= CHUNK_SIZE_Y - 1 or z < 1 or z >= CHUNK_SIZE_Z - 1:
		return false
	
	if get_voxel(x, y, z) == AIR:
		return false
	
	var solid_neighbor_count = 0
	
	var neighbor_offsets = [
		Vector3i.RIGHT, Vector3i.LEFT,
		Vector3i.UP, Vector3i.DOWN,
		Vector3i.FORWARD, Vector3i.BACK
	]
	
	for offset in neighbor_offsets:
		var neighbor_pos = Vector3i(x, y, z) + offset
		if get_voxel(neighbor_pos.x, neighbor_pos.y, neighbor_pos.z) != AIR:
			solid_neighbor_count += 1
			
	# Si no tiene ningún vecino sólido, está aislado. ¡Lo eliminamos!
	if solid_neighbor_count == 0:
		print("Limpiando vóxel huérfano en (%d, %d, %d)" % [x, y, z])
		var index = _get_voxel_index(x, y, z)
		world_data[index] = AIR
		return true
	return false

#func _interpolate_vertex(pos: Vector3, edge_index: int) -> Vector3:
	#var corner_offsets = [
		#Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1), 
		#Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)
	#]
	#
	#var edge_verts_indices = edge_table[edge_index]
	#var p1_index = edge_verts_indices[0]
	#var p2_index = edge_verts_indices[1]
	#
	#var p1_world_pos = pos + corner_offsets[p1_index]
	#var p2_world_pos = pos + corner_offsets[p2_index]
	#
	#return (p1_world_pos + p2_world_pos) / 2.0
