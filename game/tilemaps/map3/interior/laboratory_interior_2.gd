extends Node2D

const GOOD_END_NEXT_SCENE := "res://game/tilemaps/map3/level_3.tscn"

var _finished: bool = false

func _ready() -> void:
	_prepare_protocol_text()
	GameManager.basement_system_changed.connect(_on_system_changed)

func _prepare_protocol_text() -> void:
	var data = GameManager.fragments_database.get("protocolo_emergencia")
	if data == null:
		push_error("Falta 'protocolo_emergencia' en fragments.json")
		return
	if not data.has("template"):
		data["template"] = data["content"]
	var parts: Array[String] = []
	for n in GameManager.switch_order():
		parts.append(str(n))
	data["content"] = String(data["template"]).replace("{ORDEN}", " - ".join(PackedStringArray(parts)))

func _on_system_changed(_id: String, _active: bool) -> void:
	if _finished or not GameManager.all_basement_systems_done():
		return
	_finished = true
	GameManager.emergency_disabled = true
	AlarmManager.stop()
	await get_tree().create_timer(1.0).timeout
	CinematicsManager.play("final_bueno", GOOD_END_NEXT_SCENE)
