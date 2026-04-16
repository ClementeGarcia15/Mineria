extends Control

var player: Player

func set_player_reference(p: Player):
	player = p

signal shop_closed
signal pickaxe_upgraded

@onready var upgrade_button = $"Panel/VBoxContainer/UpgradeButton"
@onready var close_button = $"Panel/VBoxContainer/CloseButton"

func _ready():
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

func _on_upgrade_button_pressed():
	var upgrade_cost = 10 # Ejemplo de costo
	if player and player.inventory[VoxelWorld.STONE] >= upgrade_cost:
		player.inventory[VoxelWorld.STONE] -= upgrade_cost
		player.pickaxe_power += 10.0
		print("Pico mejorado! Nuevo poder: ", player.pickaxe_power)
		print("Inventario actualizado: ", player.inventory)
		emit_signal("pickaxe_upgraded")
	else:
		print("No tienes suficiente piedra para mejorar el pico.")

func _on_close_button_pressed():
	hide()
	emit_signal("shop_closed")
