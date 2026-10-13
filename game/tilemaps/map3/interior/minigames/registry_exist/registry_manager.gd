extends Node

const EXPECTED_ROW_COUNTS: Array[int] = [6, 8, 8, 8]
const MIN_STOCK: int = 10
const MIN_DIGIT_COUNT_TECH: int = 2
const TARGET_DIGIT_COUNT: int = 6

var registry_database: Array = []
var is_registry_valid: bool = false

var lots_by_digit: Dictionary = {}
var code_by_lot: Dictionary = {}

func _ready() -> void:
	if load_registry():
		is_registry_valid = validate_registry()
		if is_registry_valid:
			_build_pool()
		else:
			push_error("RegistryManager: falla en la validación.")
			registry_database.clear()
	else:
		registry_database.clear()

func load_registry() -> bool:
	var file_path = "res://game/tilemaps/map3/interior/minigames/registry_exist/register_workshop.json"
	
	if not FileAccess.file_exists(file_path):
		push_error("RegistryManager: No se encontró " + file_path)
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("RegistryManager: Error al abrir el archivo. Código de error: " + str(FileAccess.get_open_error()))
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("RegistryManager: JSON inválido en línea %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or not data.has("pages"):
		return false
	
	var raw_pages = data["pages"]
	if typeof(raw_pages) != TYPE_ARRAY:
		return false
		
	registry_database.clear()
	
	var regex_digit = RegEx.new()
	regex_digit.compile("\\d")
	
	for p_idx in range(raw_pages.size()):
		var page = raw_pages[p_idx]
		if typeof(page) != TYPE_DICTIONARY or not page.has("rows"):
			return false
			
		var raw_rows = page["rows"]
		if typeof(raw_rows) != TYPE_ARRAY:
			return false
			
		var processed_page = {"rows": []}
		
		for r_idx in range(raw_rows.size()):
			var row = raw_rows[r_idx]
			if typeof(row) != TYPE_DICTIONARY:
				return false
			
			var required_keys = ["lote", "descripcion", "ubicacion", "codigo", "stock"]
			for key in required_keys:
				if not row.has(key):
					return false
			
			var ubicacion = str(row["ubicacion"])
			if regex_digit.search(ubicacion):
				return false
			
			var stock = int(row["stock"])
			if stock < MIN_STOCK:
				return false
			
			var processed_row = {
				"lote": str(row["lote"]),
				"descripcion": str(row["descripcion"]),
				"ubicacion": ubicacion,
				"codigo": int(row["codigo"]),
				"stock": stock
			}
			processed_page["rows"].append(processed_row)
			
		registry_database.append(processed_page)
	
	return true

func validate_registry() -> bool:
	if registry_database.size() != EXPECTED_ROW_COUNTS.size():
		return false
		
	for i in range(registry_database.size()):
		var row_count = registry_database[i]["rows"].size()
		if row_count != EXPECTED_ROW_COUNTS[i]:
			push_error("Validación: La página " + str(i + 1) + " tiene " + str(row_count) + " filas, se esperaban " + str(EXPECTED_ROW_COUNTS[i]))
			return false
	
	var all_lotes = {}
	var digit_counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	
	for page in registry_database:
		for row in page["rows"]:
			var lote = row["lote"]
			if all_lotes.has(lote):
				push_error("Validación: Lote duplicado encontrado -> " + lote)
				return false
			all_lotes[lote] = true
			
			var cod = row["codigo"]
			if not digit_counts.has(cod):
				push_error("Validación: Código fuera de rango (1-5) -> " + str(cod))
				return false
			digit_counts[cod] += 1
	
	for cod in digit_counts.keys():
		var count = digit_counts[cod]
		if count < MIN_DIGIT_COUNT_TECH:
			push_error("Validación: El dígito " + str(cod) + " aparece " + str(count) + " veces. Rompe el mínimo técnico necesario (" + str(MIN_DIGIT_COUNT_TECH) + ")")
			return false
		elif count < TARGET_DIGIT_COUNT:
			push_warning("Validación: El dígito " + str(cod) + " aparece " + str(count) + " veces (el objetivo de variedad ideal es " + str(TARGET_DIGIT_COUNT) + ")")
	
	print("RegistryManager: Validación exitosa")
	return true

func _build_pool() -> void:
	lots_by_digit.clear()
	code_by_lot.clear()
	for page in registry_database:
		for row in page["rows"]:
			var cod: int = row["codigo"]
			if not lots_by_digit.has(cod):
				lots_by_digit[cod] = []
			lots_by_digit[cod].append(row["lote"])
			code_by_lot[row["lote"]] = cod
	
func pick_lots(key_code: Array) -> Array:
	var result: Array = []
	if not is_registry_valid:
		push_error("RegistryManager: registro invalido")
		return result
	
	var used: Dictionary = {}
	for value in key_code:
		var digit := int(value)
		var candidates: Array = []
		for lot in lots_by_digit.get(digit, []):
			if not used.has(lot):
				candidates.append(lot)
	
		if candidates.is_empty():
			push_error("RegistryManager: no hay lotes disponibles para el dígito %d." % digit)
			return []
	
		var chosen: String = candidates.pick_random()
		used[chosen] = true
		result.append(chosen)
	return result
