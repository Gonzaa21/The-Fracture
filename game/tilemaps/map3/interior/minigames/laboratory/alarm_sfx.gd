extends CanvasLayer

const AUDIO_STREAM := preload("res://assets/sound/effects/emergency/alarma.mp3")

const VOLUME_GROUND := -6.0
const VOLUME_BASEMENT := -14.0
const ALPHA_GROUND := 0.35
const ALPHA_BASEMENT := 0.18
const FLASH_DECAY := 5.0

const BEEP_TIMES := [0.46, 2.14, 3.80, 5.45] 
const AUDIO_DURATION := 6.35

var _overlay: ColorRect
var _player: AudioStreamPlayer
var _max_alpha: float = ALPHA_GROUND
var _vol_tween: Tween

func _ready() -> void:
	layer = 3
	
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(1.0, 0.1, 0.1, 0.0)
	add_child(_overlay)
	
	_player = AudioStreamPlayer.new()
	_player.stream = AUDIO_STREAM
	_player.bus = "SFX"
	_player.volume_db = VOLUME_GROUND
	add_child(_player)
	
	_player.play()
	_player.finished.connect(func(): _player.play())

func set_zone(basement: bool) -> void:
	_max_alpha = ALPHA_BASEMENT if basement else ALPHA_GROUND
	if _vol_tween and _vol_tween.is_valid():
		_vol_tween.kill()
	_vol_tween = create_tween()
	_vol_tween.tween_property(_player, "volume_db", VOLUME_BASEMENT if basement else VOLUME_GROUND, 0.5)

func _process(_delta: float) -> void:
	if not _player.playing:
		return
	
	var rate := 1.0
	if AlarmManager.speed_multiplier > 1.0:
		rate = 1.2
	if AlarmManager.time_left < 30.0:
		rate *= 1.4
	_player.pitch_scale = rate
	
	var current_time := _player.get_playback_position()
	var normalized_t := fposmod(current_time, AUDIO_DURATION)
	
	_overlay.color.a = _calculate_flash(normalized_t) * _max_alpha

func _calculate_flash(t: float) -> float:
	var f := 0.0
	
	for beep_time in BEEP_TIMES:
		var diff: float = t - beep_time
		if diff >= 0.0 and diff < 0.2:
			f = maxf(f, exp(-diff * FLASH_DECAY))
	return f
