extends CanvasLayer

signal boot_finished

@onready var panel = $Panel
@onready var boot_text = $Panel/BootText

func _ready():
	panel.visible = false
	visible = true

func start_boot():
	panel.visible = true
	Global.input_locked = true
	boot_text.text = ""
	
	await show_text("NEXUS SYSTEMS BIOS v2.4.1\n")
	await show_text("Initializing hardware...\n")
	await get_tree().create_timer(0.5).timeout
	await show_text("CPU: OK\n")
	await show_text("RAM: 16GB OK\n")
	await show_text("HDD: 500GB OK\n\n")
	await get_tree().create_timer(0.5).timeout
	await show_text("Booting NEXUS OS v3.4.7...\n")
	await get_tree().create_timer(1.0).timeout
	
	panel.visible = false
	Global.input_locked = false
	emit_signal("boot_finished")

func show_text(text: String):
	boot_text.text += text
	await get_tree().create_timer(0.2).timeout
