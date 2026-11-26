extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const BLOCKED_SCENES: Array[String] = []

# ---------- Estilo ----------
const TEXT_SELECTED_COLOR := Color(0.513, 0.408, 0.73, 1.0)
const UNDERLINE_THICKNESS := 2
const INDENT_BASE := 8
const INDENT_STEP := 14
const BAND_VERTICAL_MARGIN := 80.0

# Botón Atrás: área de clickeo compacta
const BACK_BUTTON_EXTRA_WIDTH := 12.0
const BACK_BUTTON_HEIGHT := 18.0

# Lista de controles
const CONTROLS_FONT_SIZE := 9
const CONTROLS_PER_ROW := 1
const KEY_UNDERLINE_THICKNESS := 1

# Sliders de volumen
const SLIDER_WIDTH := 60
const SLIDER_LABEL_WIDTH := 56

# Nombres lindos para las acciones de tu Input Map.
# Las acciones que no estén acá se muestran con su nombre ("move_up" -> "Move Up").
const ACTION_LABELS := {
	"ui_cancel": "Pausa",
	"interact": "Interactuar",
	"run": "Correr",
	# Agregá las tuyas, por ejemplo:
	# "move_up": "Mover arriba",
}

# Acciones que NO querés mostrar en la lista
const HIDDEN_ACTIONS: Array[String] = []

@onready var band: ColorRect = $Band
@onready var band2: ColorRect = $Band2
@onready var main_panel: Control = $Menu
@onready var settings_panel: Control = $SettingsPanel
@onready var resume_button: Button = $Menu/ResumeButton
@onready var settings_button: Button = $Menu/SettingsButton
@onready var quit_button: Button = $Menu/QuitGameButton
@onready var music_label: Label = $SettingsPanel/HBoxContainer/Label
@onready var music_slider: HSlider = $SettingsPanel/HBoxContainer/MusicSlider
@onready var sfx_label: Label = $SettingsPanel/HBoxContainer2/Label
@onready var sfx_slider: HSlider = $SettingsPanel/HBoxContainer2/SfxSlider
@onready var controls_list: Container = $SettingsPanel/ControlsList
@onready var back_button: Button = $SettingsPanel/BackButton

var fullscreen_toggle: Button
var box_off: ImageTexture
var box_on: ImageTexture

var is_open := false
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false
var main_band_height := 140.0

var _diag_pos := Vector2.ZERO
var _diag_size := Vector2.ZERO
var _diag_rot := 0.0

# Fuente pixel del proyecto, copiada de un Label que ya la usa
var ui_font: Font
var ui_font_size: int


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	
	main_band_height = band.size.y
	_diag_pos = band.position
	_diag_size = band.size
	_diag_rot = band.rotation
	
	ui_font = music_label.get_theme_font("font")
	ui_font_size = music_label.get_theme_font_size("font_size")
	
	for slider in [music_slider, sfx_slider]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
	
	_style_menu_buttons()
	_style_settings_controls()
	
	_load_settings()
	_apply_bus(BUS_MUSIC, music_volume)
	_apply_bus(BUS_SFX, sfx_volume)
	_apply_fullscreen(fullscreen)
	
	music_slider.set_value_no_signal(music_volume)
	sfx_slider.set_value_no_signal(sfx_volume)
	fullscreen_toggle.set_pressed_no_signal(fullscreen)
	_refresh_fullscreen_icon()
	
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_show_main)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and is_node_ready():
		if band and band.visible:
			_apply_main_diagonal_band(main_band_height)


# ---------- Apertura / cierre ----------
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_open:
		get_viewport().set_input_as_handled()
		if settings_panel.visible:
			_show_main()
		else:
			close()
	elif _can_open():
		get_viewport().set_input_as_handled()
		open()


func _can_open() -> bool:
	if Global.input_locked:
		return false
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path in BLOCKED_SCENES:
		return false
	return true


func open() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	_set_generator_paused(true)
	_show_main()


func close() -> void:
	_save_settings()
	is_open = false
	visible = false
	get_tree().paused = false
	_set_generator_paused(false)


func _show_main() -> void:
	_hide_all_underlines()
	band.visible = true
	band2.visible = false
	main_panel.visible = true
	settings_panel.visible = false
	_apply_main_diagonal_band(main_band_height)


func _on_settings_pressed() -> void:
	_hide_all_underlines()
	_build_controls_list()
	fullscreen_toggle.set_pressed_no_signal(_is_window_fullscreen())
	_refresh_fullscreen_icon()
	band.visible = false
	band2.visible = true
	main_panel.visible = false
	settings_panel.visible = true
	_shrink_back_button_hit_area()


func _on_quit_pressed() -> void:
	_save_settings()
	get_tree().quit()


func _set_generator_paused(paused: bool) -> void:
	if GameManager.generator_player:
		GameManager.generator_player.stream_paused = paused


func _apply_main_diagonal_band(h: float) -> void:
	var viewport_h := get_viewport().get_visible_rect().size.y
	var cos_r := absf(cos(_diag_rot))
	var sin_r := absf(sin(_diag_rot))

	var needed_height := maxf(h, viewport_h + BAND_VERTICAL_MARGIN)
	if cos_r > 0.05:
		needed_height = maxf(needed_height, (viewport_h + BAND_VERTICAL_MARGIN + _diag_size.x * sin_r) / cos_r)

	var center := _diag_pos + _diag_size / 2.0
	band.rotation = _diag_rot
	band.size = Vector2(_diag_size.x, needed_height)
	band.pivot_offset = band.size / 2.0
	band.position = center - band.size / 2.0


# ---------- Estilo: botones del menú (subrayado en hover) ----------
func _style_menu_buttons() -> void:
	var buttons: Array[Button] = [resume_button, settings_button, quit_button]
	for i in buttons.size():
		_make_underline_button(buttons[i], INDENT_BASE + i * INDENT_STEP)


func _make_underline_button(b: Button, indent: float) -> void:
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE

	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color(0, 0, 0, 0)
	transparent.content_margin_left = indent
	transparent.content_margin_top = 3
	transparent.content_margin_bottom = 3
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, transparent)

	b.add_theme_color_override("font_hover_color", TEXT_SELECTED_COLOR)
	b.add_theme_color_override("font_pressed_color", TEXT_SELECTED_COLOR)

	var underline := ColorRect.new()
	underline.name = "Underline"
	underline.color = TEXT_SELECTED_COLOR
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underline.visible = false
	b.add_child(underline)

	b.mouse_entered.connect(_on_button_hover_enter.bind(b, underline, indent))
	b.mouse_exited.connect(_on_button_hover_exit.bind(underline))


func _shrink_back_button_hit_area() -> void:
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var font := back_button.get_theme_font("font")
	var font_size := back_button.get_theme_font_size("font_size")
	var text_w := 0.0
	if font:
		text_w = font.get_string_size(back_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	var compact_w := maxf(24.0, text_w + INDENT_BASE + BACK_BUTTON_EXTRA_WIDTH)
	back_button.custom_minimum_size = Vector2(compact_w, BACK_BUTTON_HEIGHT)
	back_button.size = Vector2(compact_w, BACK_BUTTON_HEIGHT)


func _on_button_hover_enter(b: Button, underline: ColorRect, indent: float) -> void:
	var font := b.get_theme_font("font")
	var font_size := b.get_theme_font_size("font_size")
	var text_width := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	underline.size = Vector2(text_width, UNDERLINE_THICKNESS)
	underline.position = Vector2(indent, b.size.y - UNDERLINE_THICKNESS)
	underline.visible = true


func _on_button_hover_exit(underline: ColorRect) -> void:
	underline.visible = false


func _hide_all_underlines() -> void:
	for b in [resume_button, settings_button, quit_button, back_button]:
		var u = b.get_node_or_null("Underline")
		if u:
			u.visible = false


# ---------- Estilo: panel de configuración ----------
func _style_settings_controls() -> void:
	_make_underline_button(back_button, INDENT_BASE)
	_shrink_back_button_hit_area()

	_style_slider_row(music_label, music_slider)
	_style_slider_row(sfx_label, sfx_slider)
	for s in [music_slider, sfx_slider]:
		_style_slider(s)

	box_off = _make_box_texture(Vector2i(8, 8), Color(0.1, 0.1, 0.12), TEXT_SELECTED_COLOR)
	box_on = _make_box_texture(Vector2i(8, 8), TEXT_SELECTED_COLOR, TEXT_SELECTED_COLOR)
	_build_fullscreen_toggle()


func _style_slider_row(label: Label, slider: HSlider) -> void:
	var row := label.get_parent()
	if row is HBoxContainer:
		row.add_theme_constant_override("separation", 6)

	label.custom_minimum_size.x = SLIDER_LABEL_WIDTH
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	slider.custom_minimum_size.x = SLIDER_WIDTH
	slider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	track.content_margin_top = 2
	track.content_margin_bottom = 2

	var filled := StyleBoxFlat.new()
	filled.bg_color = TEXT_SELECTED_COLOR
	filled.content_margin_top = 2
	filled.content_margin_bottom = 2

	var filled_hover := filled.duplicate() as StyleBoxFlat
	filled_hover.bg_color = TEXT_SELECTED_COLOR.lightened(0.25)

	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", filled)
	s.add_theme_stylebox_override("grabber_area_highlight", filled_hover)
	s.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var light := TEXT_SELECTED_COLOR.lightened(0.4)
	s.add_theme_icon_override("grabber", _make_box_texture(Vector2i(5, 9), Color.WHITE, Color.WHITE))
	s.add_theme_icon_override("grabber_highlight", _make_box_texture(Vector2i(5, 9), light, light))
	s.add_theme_icon_override("grabber_disabled", _make_box_texture(Vector2i(5, 9), Color.GRAY, Color.GRAY))


# Reemplaza el CheckButton de la escena por un Button con el cuadrito a la izquierda
func _build_fullscreen_toggle() -> void:
	var original := $SettingsPanel/FullscreenCheck as Button
	var caption := original.text if original.text != "" else "PANTALLA COMPLETA"
	var parent := original.get_parent()
	var index := original.get_index()
	parent.remove_child(original)
	original.queue_free()

	fullscreen_toggle = Button.new()
	fullscreen_toggle.name = "FullscreenToggle"
	fullscreen_toggle.toggle_mode = true
	fullscreen_toggle.text = caption
	fullscreen_toggle.flat = true
	fullscreen_toggle.focus_mode = Control.FOCUS_NONE
	fullscreen_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	fullscreen_toggle.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fullscreen_toggle.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	fullscreen_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fullscreen_toggle.add_theme_constant_override("h_separation", 6)
	fullscreen_toggle.add_theme_font_override("font", ui_font)
	fullscreen_toggle.add_theme_font_size_override("font_size", ui_font_size)
	fullscreen_toggle.add_theme_color_override("font_color", Color.WHITE)
	fullscreen_toggle.add_theme_color_override("font_pressed_color", Color.WHITE)
	fullscreen_toggle.add_theme_color_override("font_hover_color", TEXT_SELECTED_COLOR)
	fullscreen_toggle.add_theme_color_override("font_hover_pressed_color", TEXT_SELECTED_COLOR)

	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		fullscreen_toggle.add_theme_stylebox_override(state, empty)

	parent.add_child(fullscreen_toggle)
	parent.move_child(fullscreen_toggle, index)


func _refresh_fullscreen_icon() -> void:
	fullscreen_toggle.icon = box_on if fullscreen_toggle.button_pressed else box_off


func _make_box_texture(size: Vector2i, fill: Color, border: Color) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(border)
	if size.x > 2 and size.y > 2:
		img.fill_rect(Rect2i(1, 1, size.x - 2, size.y - 2), fill)
	return ImageTexture.create_from_image(img)


func _make_ui_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


# ---------- Ajustes ----------
func _on_music_changed(value: float) -> void:
	music_volume = value
	_apply_bus(BUS_MUSIC, value)


func _on_sfx_changed(value: float) -> void:
	sfx_volume = value
	_apply_bus(BUS_SFX, value)


func _on_fullscreen_toggled(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen(on)
	_refresh_fullscreen_icon()


func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("PauseMenu: no existe el bus " + bus_name)
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	if linear > 0.001:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


func _apply_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _is_window_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


# ---------- Persistencia ----------
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx", 1.0)
	fullscreen = cfg.get_value("video", "fullscreen", false)


# ---------- Lista de controles ----------
# Lee las acciones reales del Input Map (sin las "ui_" internas de Godot, salvo ui_cancel)
func _collect_control_entries() -> Array:
	var entries: Array = []
	for action in InputMap.get_actions():
		var action_name := String(action)
		if action_name.begins_with("ui_") and action_name != "ui_cancel":
			continue
		if action_name in HIDDEN_ACTIONS:
			continue
		if InputMap.action_get_events(action_name).is_empty():
			continue
		var label_text: String = ACTION_LABELS.get(action_name, action_name.replace("_", " ").capitalize())
		entries.append([action_name, label_text])
	return entries


func _build_controls_list() -> void:
	for child in controls_list.get_children():
		controls_list.remove_child(child)
		child.queue_free()
	
	var grid := GridContainer.new()
	grid.columns = CONTROLS_PER_ROW * 2 + (CONTROLS_PER_ROW - 1)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 2)
	controls_list.add_child(grid)
	
	var count := 0
	for entry in _collect_control_entries():
		if count % CONTROLS_PER_ROW != 0:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(10, 0)
			grid.add_child(spacer)
	
		grid.add_child(_make_ui_label(entry[1], CONTROLS_FONT_SIZE))
		grid.add_child(_make_key_label(_action_to_text(entry[0])))
		count += 1
	
	# Reservar el alto real de la grilla: evita que se superponga con el botón Volver
	controls_list.custom_minimum_size = grid.get_combined_minimum_size()

func _make_key_label(text: String) -> Label:
	var label := _make_ui_label(text, CONTROLS_FONT_SIZE)

	var width := ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, CONTROLS_FONT_SIZE).x
	var line := ColorRect.new()
	line.color = TEXT_SELECTED_COLOR
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.anchor_left = 0.0
	line.anchor_right = 0.0
	line.anchor_top = 1.0
	line.anchor_bottom = 1.0
	line.offset_left = 0.0
	line.offset_right = width
	line.offset_top = -KEY_UNDERLINE_THICKNESS
	line.offset_bottom = 0.0
	label.add_child(line)
	return label


func _action_to_text(action: String) -> String:
	var parts: Array[String] = []
	for e in InputMap.action_get_events(action):
		parts.append(_event_to_text(e))
	return " / ".join(parts)


func _event_to_text(e: InputEvent) -> String:
	var text := ""
	if e is InputEventKey:
		if e.physical_keycode != KEY_NONE:
			var mapped := DisplayServer.keyboard_get_keycode_from_physical(e.physical_keycode)
			text = OS.get_keycode_string(mapped)
		else:
			text = OS.get_keycode_string(e.keycode)
	else:
		text = e.as_text()
	return text.replace("Escape", "Esc")
