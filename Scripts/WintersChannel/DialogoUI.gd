extends CanvasLayer

signal linea_terminada

@onready var contenedor = $ContenedorCuadro
@onready var lbl_nombre = $ContenedorCuadro/FondoNegro/LblNombre
@onready var retrato = $ContenedorCuadro/FondoNegro/HBox/Retrato
@onready var texto_dialogo = $ContenedorCuadro/FondoNegro/HBox/TextoDialogo

var esta_escribiendo: bool = false
var caracteres_mostrados: float = 0.0
var velocidad_texto: float = 40.0 # Letras por segundo

func _ready():
	hide() # Ocultamos el cuadro al iniciar el juego
	texto_dialogo.visible_characters = 0

func mostrar_linea(datos: Dictionary):
	show()
	
	# 1. Nombre
	if datos["nombre"] == "" or datos["nombre"] == "null":
		lbl_nombre.text = ""
	else:
		lbl_nombre.text = datos["nombre"]
		
	# 2. Retrato
	if datos["retrato"] == "" or datos["retrato"] == "null":
		retrato.hide()
	else:
		retrato.show()
		# Aquí asumo que guardarás los retratos en "res://assets/retratos/"
		# ¡Ajusta esta ruta según la carpeta de tu juego!
		var ruta = "res://assets/retratos/" + datos["retrato"] + ".png"
		if ResourceLoader.exists(ruta):
			retrato.texture = load(ruta)
		
	# 3. Preparar el Texto y la animación
	texto_dialogo.text = datos["texto"]
	texto_dialogo.visible_characters = 0
	caracteres_mostrados = 0.0
	esta_escribiendo = true

func _process(delta):
	if esta_escribiendo:
		# Máquina de escribir: vamos sumando caracteres poco a poco
		caracteres_mostrados += velocidad_texto * delta
		texto_dialogo.visible_characters = int(caracteres_mostrados)
		
		# Si ya se mostró todo, nos detenemos
		if texto_dialogo.visible_characters >= texto_dialogo.get_total_character_count():
			esta_escribiendo = false

func _input(event):
	# Si presionas 'Aceptar' (Z, Enter, Espacio)...
	if visible and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		
		if esta_escribiendo:
			# Si está escribiendo, saltamos la animación y mostramos todo de golpe
			texto_dialogo.visible_characters = texto_dialogo.get_total_character_count()
			esta_escribiendo = false
		else:
			# Si ya terminó de escribir, pasamos a la siguiente línea
			linea_terminada.emit()

func actualizar_posicion(jugador: Node2D):
	var altura_pantalla = get_viewport().get_visible_rect().size.y
	
	if jugador == null:
		# Si no hay jugador, lo dejamos abajo por defecto sin aplastarlo
		contenedor.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
		contenedor.position.y = altura_pantalla - contenedor.size.y
		return
		
	# Obtenemos la posición del jugador en la pantalla
	var pos_pantalla = jugador.get_global_transform_with_canvas().origin
	
	# Si el jugador está en la mitad inferior de la pantalla, subimos el cuadro
	if pos_pantalla.y > (altura_pantalla / 2.0):
		# Lo anclamos al centro-arriba y le PROHIBIMOS cambiar de tamaño
		contenedor.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE)
		
		# Lo pegamos exactamente al techo (0 espacio libre)
		contenedor.position.y = 0 
	else:
		# Si el jugador está arriba, bajamos el cuadro
		contenedor.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
		
		# Lo pegamos exactamente al suelo
		contenedor.position.y = altura_pantalla - contenedor.size.y
