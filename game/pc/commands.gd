class_name TerminalCommands
extends RefCounted

static func cmd_help(terminal) -> void:
	terminal.print_line("Available commands:")
	terminal.print_line("")
	terminal.print_line(" help               : Display this help message")
	terminal.print_line(" dir                : List files and folders in current directory")
	terminal.print_line(" cd <dir>           : Change directory (cd .. to go back)")
	terminal.print_line(" type <file.txt>    : Display contents of a file")
	terminal.print_line(" netstat            : Display network connections")
	terminal.print_line(" exit               : Close terminal")

static func cmd_dir(terminal) -> void:
	var current_dir = GameManager.current_directory
	var directories = GameManager.filesystem_data.get("directories", {})
	
	if not directories.has(current_dir):
		terminal.print_line("ERROR: Directory not found in filesystem.")
		return
	var dir_data = directories[current_dir]
	var folders = dir_data.get("folders", [])
	var files = dir_data.get("files", [])
	
	terminal.print_line("Directory of " + current_dir)
	terminal.print_line("")
	
	# Mostrar carpetas primero
	for folder in folders:
		terminal.print_line("10/1/2026     16:26  " + "  <DIR>  " + folder)
	
	# Mostrar archivos
	for file in files:
		if file == "Protocolo_Phoenix.txt" and GameManager.phoenix_viewed:
			continue  # No mostrar si ya fue eliminado
		
		terminal.print_line("10/1/2026     16:26  " + "         " + file)
	
	terminal.print_line("")
	var total = folders.size() + files.size()
	terminal.print_line("         " + str(total) + " File(s)")

static func cmd_cd(terminal, argument: String) -> void:
	# Si no hay argumento, mostrar directorio actual
	if argument == "":
		terminal.print_line(GameManager.current_directory)
		return
	
	var current_dir = GameManager.current_directory
	var directories = GameManager.filesystem_data.get("directories", {})
	
	# Caso especial: cd ..
	if argument == "..":
		# Volver al directorio padre
		var parts = current_dir.split("\\")
		if parts.size() <= 2:  # Ya estamos en C:\ o C:\Users
			terminal.print_line("Already at root or top level.")
			return
		
		# Eliminar la última parte del path
		parts.remove_at(parts.size() - 1)
		var parent_dir = "\\".join(parts)
		
		if directories.has(parent_dir):
			GameManager.current_directory = parent_dir
			terminal.update_prompt()
		else:
			terminal.print_line("ERROR: Parent directory not found.")
		return
	
	# Verificar si el directorio actual existe
	if not directories.has(current_dir):
		terminal.print_line("ERROR: Current directory not found.")
		return
	
	var dir_data = directories[current_dir]
	var folders = dir_data.get("folders", [])
	
	#Buscar carpeta case-insensitive
	var matched_folder = ""
	for folder in folders:
		if folder.to_lower() == argument.to_lower():
			matched_folder = folder
			break
	
	if matched_folder == "":
		terminal.print_line("The system cannot find the path specified.")
		return

	var target_dir = current_dir + "\\" + matched_folder
	
	# Verificar si el directorio destino existe
	if not directories.has(target_dir):
		terminal.print_line("ERROR: Target directory not found in filesystem.")
		return
	
	# Cambiar directorio
	GameManager.current_directory = target_dir
	terminal.update_prompt()

static func cmd_type(terminal, argument: String) -> void:
	if argument == "":
		terminal.print_line("The syntax of the command is incorrect.")
		return
	
	var current_dir = GameManager.current_directory
	var directories = GameManager.filesystem_data.get("directories", {})
	var file_contents = GameManager.filesystem_data.get("file_contents", {})
	
	# Verificar que el directorio actual existe
	if not directories.has(current_dir):
		terminal.print_line("ERROR: Current directory not found.")
		return
	
	var dir_data = directories[current_dir]
	var files = dir_data.get("files", [])
	
	# Buscar archivo case-insensitive
	var matched_file = ""
	for file in files:
		if file.to_lower() == argument.to_lower():
			matched_file = file
			break
	
	if matched_file == "":
		terminal.print_line("The system cannot find the file specified.")
		return
	
	#Verificar si es el Protocolo Phoenix y ya fue visto (usar matched_file)
	if matched_file == "Protocolo_Phoenix.txt" and GameManager.phoenix_viewed:
		terminal.print_line("The system cannot find the file specified.")
		return
	
	if not file_contents.has(matched_file):
		terminal.print_line("ERROR: File content not found in database.")
		return
	
	var content = file_contents[matched_file]
	
	# Manejar archivos especiales
	if content == "[SYSTEM_FILE]":
		terminal.print_line("ERROR: Cannot display system file.")
		return
		
	if content == "[PDF_FILE]":
		terminal.print_line("ERROR: (0x80070005) Access is Denied. Location Not Available.")
		return
	
	if content == "[CISCO_FILE]":
		terminal.print_line("ERROR: This content is restricted.\nIf you believe you should have access, contact the Data Owner or the CISCO Office.")
		return
	
	if content == "[EXE_FILE]":
		terminal.print_line("ERROR: System Administrator Blocked This App.")
		return
	
	if content == "[BINARY_FILE]":
		terminal.print_line("ERROR: Cannot display binary file in text format.")
		return
	
	if content.begins_with("[SPECIAL_TRIGGER:"):
		terminal.handle_special_file(content)
		return
	
	if content == "[ENCRYPTED_FILE]":
		terminal.print_line("═══════════════════════════════════════")
		terminal.print_line("       ENCRYPTED FILE DENIED")
		terminal.print_line("")
		terminal.print_line("The file could not be opened because it is encrypted with")
		terminal.print_line("software that is not installed on this computer.")
		terminal.print_line("═══════════════════════════════════════")
		return
	
	# Archivo normal, mostrar contenido
	terminal.print_line(content)
	
static func cmd_netstat(_terminal) -> void:
	pass

static func cmd_exit(terminal) -> void:
	await terminal.get_tree().create_timer(0.5).timeout
	terminal.close_terminal()
