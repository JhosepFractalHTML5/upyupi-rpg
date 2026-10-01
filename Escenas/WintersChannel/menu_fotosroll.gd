extends Panel

# --- REFERENCIAS INTERNAS ---
@onready var zona_carrusel = $ZonaCarrusel
@onready var pista_movimiento = $ZonaCarrusel/PistaMovimiento
@onready var pop_up_opciones = $PopUpOpciones
@onready var contenedor_pjs = $PopUpOpciones/VBox/ContenedorPJs
@onready var lbl_pregunta = $PopUpOpciones/VBox/LblPregunta
@onready var btn_grupo_entero = $PopUpOpciones/VBox/BtnGrupoEntero

# --- MEMORIA DEL CARRUSEL ---
var fotos_disponibles: Array[String] = []
var indice_columna_x: int = 0

const ESPACIO_X = 200 # Distancia horizontal entre columnas
const CENTRO_PANTALLA_X = 935 # Ajusta esto en el editor para que la columna quede en el centro exacto

func _ready():
	# Nos aseguramos de que el popup inicie apagado
	pop_up_opciones.hide()

func abrir():
	pop_up_opciones.hide()
	# Copiamos la lista de contextos ("NORMAL", "PRIS", etc.)
	fotos_disponibles = GlobalGame.inventario_fotos_roll.duplicate()
	indice_columna_x = 0
	pista_movimiento.position.y = 162
	
	# Limpiamos la pista por si abriste el menú antes
	for hijo in pista_movimiento.get_children():
		pista_movimiento.remove_child(hijo)
		hijo.queue_free()
		
	# Generamos las columnas
	for i in range(fotos_disponibles.size()):
		var contexto = fotos_disponibles[i]
		
		# 1. Contenedor de la columna
		var columna = Control.new()
		columna.name = "Columna_" + contexto
		columna.position.x = i * ESPACIO_X
		columna.size = Vector2(140, 600)
		columna.pivot_offset = Vector2(70, 300) # Crece desde el centro
		pista_movimiento.add_child(columna)
		
		# 2. VBox para apilar a los 4 protagonistas verticalmente
		var vbox = VBoxContainer.new()
		columna.add_child(vbox) # <--- ¡AHORA SÍ! Primero lo hacemos hijo...
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # ...y luego lo anclamos.
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 12)
		
		# 3. Cargamos los 4 PNGs desde sus carpetas
		var protas = ["Jhosep", "Romn", "Massi", "Thais"]
		for p in protas:
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(140, 140)
			tex.size = Vector2(140, 140) 
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# ¡Corregido! Ruta: res://Graficos/Batalla/Protagonistas/FotoRoll/NORMAL/JhosepNORMAL.png
			var ruta_img = "res://Graficos/Batalla/Protagonistas/FotoRoll/" + contexto + "/" + p + contexto + ".png"
			
			if ResourceLoader.exists(ruta_img):
				tex.texture = load(ruta_img)
			else:
				# Si no encuentra la imagen, dibuja un espacio oscuro 
				tex.modulate = Color(0.2, 0.2, 0.2, 0.5) 
				
			vbox.add_child(tex)
			
	show()
	call_deferred("_actualizar_visual", true)

func _input(event):
	if not visible or fotos_disponibles.is_empty(): return
	
	# --- CONTROL DEL POPUP ABIERTO ---
	if pop_up_opciones.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			pop_up_opciones.hide()
		return
		
	# --- CONTROLES DEL CARRUSEL ---
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		if indice_columna_x > 0:
			indice_columna_x -= 1
			_actualizar_visual()
			
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		if indice_columna_x < fotos_disponibles.size() - 1:
			indice_columna_x += 1
			_actualizar_visual()
			
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		var contexto_elegido = fotos_disponibles[indice_columna_x]
		_preparar_popup(contexto_elegido)


# --- FASE 4: LÓGICA DE APLICACIÓN DE FOTOS ---

func _preparar_popup(contexto: String):
	lbl_pregunta.text = "¿Aplicar fotos " + contexto + " a...?"
	
	# 1. Reconectar el botón del grupo entero para pasarle el contexto actual
	if btn_grupo_entero.pressed.is_connected(_on_btn_grupo_entero_pressed):
		btn_grupo_entero.pressed.disconnect(_on_btn_grupo_entero_pressed)
	btn_grupo_entero.pressed.connect(_on_btn_grupo_entero_pressed.bind(contexto))
	
	# 2. Limpiar el contenedor de los protagonistas individuales
	for hijo in contenedor_pjs.get_children():
		contenedor_pjs.remove_child(hijo)
		hijo.queue_free()
		
	# 3. Generar un botón por cada miembro vivo en la party
	for heroe in GlobalGame.party_actual:
		var btn_pj = Button.new()
		btn_pj.text = heroe.nombre
		btn_pj.pressed.connect(_on_btn_un_personaje_pressed.bind(contexto, heroe))
		contenedor_pjs.add_child(btn_pj)
		
	# 4. Mostrar y dar foco al primer botón
	pop_up_opciones.show()
	btn_grupo_entero.grab_focus()

func _on_btn_grupo_entero_pressed(contexto: String):
	# Recorremos la party y aplicamos a todos
	for heroe in GlobalGame.party_actual:
		_aplicar_textura(contexto, heroe)
	_cerrar_popup_y_actualizar()

func _on_btn_un_personaje_pressed(contexto: String, heroe: CharacterStats):
	# Aplicamos solo al que seleccionaste
	_aplicar_textura(contexto, heroe)
	_cerrar_popup_y_actualizar()

func _aplicar_textura(contexto: String, heroe: CharacterStats):
	# Armamos el rompecabezas: Ej: "res://.../NORMAL/JhosepNORMAL.png"
	var ruta_img = "res://Graficos/Batalla/Protagonistas/FotoRoll/" + contexto + "/" + heroe.nombre + contexto + ".png"
	
	if ResourceLoader.exists(ruta_img):
		heroe.textura_panel = load(ruta_img)
		print("[FOTOSROLL] Textura de panel actualizada para " + heroe.nombre)
	else:
		print("[FOTOSROLL] ADVERTENCIA: No se encontró la textura " + ruta_img)

func _cerrar_popup_y_actualizar():
	pop_up_opciones.hide()
	# Pedimos al menú principal que recargue las barras y fondos para ver el cambio inmediato
	if get_parent().has_method("actualizar_menu"):
		get_parent().actualizar_menu()

func _actualizar_visual(instantaneo: bool = false):
	var tween
	if not instantaneo:
		tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var tiempo_anim = 0.0 if instantaneo else 0.25
	
	# Mover la pista entera horizontalmente
	var target_x = (-indice_columna_x * ESPACIO_X) + CENTRO_PANTALLA_X
	
	if instantaneo:
		pista_movimiento.position.x = target_x
	else:
		tween.tween_property(pista_movimiento, "position:x", target_x, tiempo_anim)
		
	# Escalar la columna activa (centro) y oscurecer las inactivas (costados)
	for i in range(fotos_disponibles.size()):
		var columna = pista_movimiento.get_child(i)
		var distancia = abs(i - indice_columna_x)
		
		if distancia == 0:
			if instantaneo:
				columna.scale = Vector2(1.1, 1.1)
				columna.modulate = Color(1, 1, 1, 1.0)
			else:
				tween.tween_property(columna, "scale", Vector2(1.1, 1.1), tiempo_anim)
				tween.tween_property(columna, "modulate", Color(1, 1, 1, 1.0), tiempo_anim)
		else:
			if instantaneo:
				columna.scale = Vector2(0.8, 0.8)
				columna.modulate = Color(0.4, 0.4, 0.4, 0.6)
			else:
				tween.tween_property(columna, "scale", Vector2(0.8, 0.8), tiempo_anim)
				tween.tween_property(columna, "modulate", Color(0.4, 0.4, 0.4, 0.6), tiempo_anim)
