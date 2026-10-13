extends CanvasLayer
class_name RegisterPopup

@onready var lot: Label = $Page1/Lot
@onready var description: Label = $Page1/Description
@onready var ubication: Label = $Page1/Ubication
@onready var code: Label = $Page1/Code
@onready var stock: Label = $Page1/Stock

const COLUMNS := [
	{"field": "lote", "node": "Lot"},
	{"field": "descripcion", "node": "Description"},
	{"field": "ubicacion", "node": "Ubication"},
	{"field": "codigo", "node": "Code"},
	{"field": "stock", "node": "Stock"},
]
const COLUMN_WIDTHS := [18.0, 38.0, 33.0, 33.0, 25.0]

const PAGE_LAYOUTS := [
	{ # Page1
		"first_row": [Vector2(21, 60), Vector2(39, 61), Vector2(77, 64), Vector2(110, 65), Vector2(143, 67)],
		"row_step": Vector2(-1, 11.2),
	},
	{ # Page2
		"first_row": [Vector2(22, 36), Vector2(41.257, 37.987), Vector2(78.452, 39.486), Vector2(117.713, 40.426), Vector2(149.626, 41.8)],
		"row_step": Vector2(0, 12),
	},
	{ # Page3
		"first_row": [Vector2(18, 53), Vector2(38, 52), Vector2(75.503, 51.016), Vector2(114.713, 50.426), Vector2(146.626, 50.8)],
		"row_step": Vector2(0.5, 12),
	},
	{ # Page4
		"first_row": [Vector2(21.696, 35.151), Vector2(41.781, 35.377), Vector2(78.755, 38.061), Vector2(118.735, 38.866), Vector2(149.676, 40.788)],
		"row_step": Vector2(-0.5, 12),
	},
]

var pages: Array = []

func _ready() -> void:
	$CloseButton.pressed.connect(queue_free)
	if not RegistryManager.is_registry_valid:
		push_warning("RegisterPopup: el registro no es válido")
		return
	
	pages = [$Page1, $Page2, $Page3, $Page4]
	
	var templates: Array = []
	for col in COLUMNS:
		templates.append($Page1.get_node(col["node"]))
 
	var db: Array = RegistryManager.registry_database
	for p in db.size():
		if p >= PAGE_LAYOUTS.size() or p >= pages.size():
			push_warning("RegisterPopup: la hoja %d todavía no tiene layout" % (p + 1))
			continue
		_fill_page(pages[p], db[p]["rows"], PAGE_LAYOUTS[p], templates)
	
	for t in templates:
		t.queue_free()


func _fill_page(page: Control, rows: Array, layout: Dictionary, templates: Array) -> void:
	for r in rows.size():
		for c in COLUMNS.size():
			var label: Label = templates[c].duplicate()
			var text := str(rows[r][COLUMNS[c]["field"]])
			label.text = text
			label.position = (layout["first_row"][c] + layout["row_step"] * r).round()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			page.add_child(label)
			_check_fit(label, text, c, r, page.name)

func _check_fit(label: Label, text: String, col: int, row: int, page_name: String) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if width > COLUMN_WIDTHS[col]:
		push_warning("%s fila %d, columna '%s': '%s' mide %d px y la columna tiene ~%d" % [
			page_name, row + 1, COLUMNS[col]["field"], text, int(width), int(COLUMN_WIDTHS[col])
		])
