extends Node

var base_de_datos_dialogos: Dictionary = {}
var ui_dialogo: Node = null

var conversacion_actual: Array = []
var indice_linea: int = 0
var dialogo_activo: bool = false
var jugador_actual: Node2D = null

func _ready():
	# 1. Leemos el archivo del escritor
	# Recuerda meter el archivo CSV de tu amigo y renombrarlo a "dialogos.txt"
	cargar_csv("res://Dialogos/TEST/dialogos.txt") 
	
	# 2. Invocamos tu escena UI al juego para que siempre esté lista
	var escena_ui = preload("res://Escenas/WintersChannel/DialogoUI.tscn") # ¡Ajusta esta ruta si es necesario!
	ui_dialogo = escena_ui.instantiate()
	add_child(ui_dialogo)
	
	# Conectamos la señal para saber cuándo avanzar
	ui_dialogo.linea_terminada.connect(_siguiente_linea)

func cargar_csv(ruta: String):
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if archivo:
		var cabeceras = archivo.get_csv_line() # Ignoramos la primera línea (los títulos)
		
		while not archivo.eof_reached():
			var linea = archivo.get_csv_line()
			if linea.size() < 4: continue # Ignoramos filas vacías
			
			var id_conv = linea[0]
			var dict_linea = {
				"nombre": linea[1],
				"retrato": linea[2],
				"texto": linea[3],
				"efecto": linea[4] if linea.size() > 4 else ""
			}
			
			if not base_de_datos_dialogos.has(id_conv):
				base_de_datos_dialogos[id_conv] = []
				
			base_de_datos_dialogos[id_conv].append(dict_linea)
		archivo.close()
		print("[SISTEMA] ¡Diálogos cargados exitosamente!")

func iniciar_dialogo(id_conversacion: String, jugador: Node2D = null):
	if base_de_datos_dialogos.has(id_conversacion):
		dialogo_activo = true
		conversacion_actual = base_de_datos_dialogos[id_conversacion]
		indice_linea = 0
		jugador_actual = jugador # <--- Guardamos al jugador
		
		_siguiente_linea()
	else:
		print("Error: No encontré la conversación llamada: ", id_conversacion)

func _siguiente_linea():
	if indice_linea < conversacion_actual.size():
		var datos = conversacion_actual[indice_linea]
		
		# 1. Esquivamos al jugador antes de mostrar el cuadro
		ui_dialogo.actualizar_posicion(jugador_actual)
		
		# 2. Mostramos el texto y retrato
		ui_dialogo.mostrar_linea(datos)
		
		# 3. ¡REVISAMOS SI HAY EFECTOS ESPECIALES!
		var efecto = datos.get("efecto", "").strip_edges()
		if efecto != "":
			procesar_efecto(efecto)
			
		indice_linea += 1
	else:
		# Se acabaron las líneas
		ui_dialogo.hide()
		dialogo_activo = false
		jugador_actual = null # Limpiamos la referencia

func procesar_efecto(efecto: String):
	# Usamos un 'match' (el equivalente a un 'switch') para organizar los efectos
	match efecto:
		"temblor":
			print("[EFECTO] ¡La pantalla tiembla!")
			# Aquí puedes llamar a una función de temblor de cámara
			# Ej: jugador_actual.get_node("Camera2D").aplicar_temblor()
		"sonido_sorpresa":
			print("[EFECTO] Suena un efecto sorpresa")
			# Ej: $AudioStreamPlayer.play()
		"curar_party":
			print("[EFECTO] La party se curó durante el diálogo")
			# Ej: GlobalGame.curar_a_todos()
		_:
			print("Efecto no reconocido: ", efecto)
