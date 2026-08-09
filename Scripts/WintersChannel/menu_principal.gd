extends CanvasLayer

@onready var contenedor_personajes = $ContenedorPersonajes

# Nodos de abajo
@onready var btn_items = $ContenedorAbajo/FondoOpciones/HBoxContainer/BtnItems
@onready var lbl_whenes = $ContenedorAbajo/FondoWhenes/LblWhenes

# --- NUEVOS NODOS (FASE 1) ---
@onready var panel_categorias = $PanelCategoriasItems
@onready var btn_consumibles = $PanelCategoriasItems/VBox/BtnConsumibles
@onready var btn_coleccion = $PanelCategoriasItems/VBox/BtnColeccion
@onready var btn_claves = $PanelCategoriasItems/VBox/BtnClaves

# --- REFERENCIAS AL INVENTARIO VISUAL ---
@onready var panel_gran_inventario = $PanelGranInventario # (O la ruta correcta si lo metiste en otro lado)
@onready var lbl_nombre_item = $PanelGranInventario/HBoxPrincipal/LadoDetalles/LblNombreItem
@onready var textura_mano = $PanelGranInventario/HBoxPrincipal/LadoDetalles/CajaIlustracion/TexturaMano
@onready var textura_item_centro = $PanelGranInventario/HBoxPrincipal/LadoDetalles/CajaIlustracion/TexturaItemCentro
@onready var lbl_descripcion = $PanelGranInventario/HBoxPrincipal/LadoDetalles/LblDescripcion
@onready var grid_items = $PanelGranInventario/HBoxPrincipal/ScrollMochila/GridItems

var personaje_viendo_inventario: CharacterStats = null

# --- MÁQUINA DE ESTADOS (¡Actualizada con la fase de Inventario!) ---
enum EstadoMenu { PRINCIPAL, SELECCIONANDO_CATEGORIA_ITEMS, SELECCIONANDO_PJ_ITEMS, VIENDO_INVENTARIO }
var estado_actual = EstadoMenu.PRINCIPAL

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if panel_categorias: panel_categorias.hide() # Lo ocultamos al nacer
	if panel_gran_inventario: panel_gran_inventario.hide() # <-- ¡NUEVO! Ocultamos el gigante al nacer
	
	# Conexiones Automáticas
	if btn_items: btn_items.pressed.connect(_on_btn_items_pressed)
	
	# Nuevas conexiones de categorías
	if btn_consumibles: btn_consumibles.pressed.connect(_on_btn_consumibles_pressed)
	if btn_coleccion: btn_coleccion.pressed.connect(_on_btn_coleccion_pressed)
	if btn_claves: btn_claves.pressed.connect(_on_btn_claves_pressed)
		
	var paneles = contenedor_personajes.get_children()
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn:
			btn.pressed.connect(_on_personaje_seleccionado.bind(i))

func _input(event):
	if GestorDialogos.dialogo_activo: return
	
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		
		if visible:
			# --- LA NUEVA ESCALERA DE RETROCESO ---
			if estado_actual == EstadoMenu.VIENDO_INVENTARIO:
				panel_gran_inventario.hide() # Ocultamos el gigante
				cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS) # Volvemos a los personajes
			elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
				cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)
			elif estado_actual == EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS:
				cambiar_estado(EstadoMenu.PRINCIPAL)
			else:
				cerrar_menu()
		else:
			abrir_menu()

func abrir_menu():
	show()
	actualizar_menu()
	get_tree().paused = true
	cambiar_estado(EstadoMenu.PRINCIPAL) 

func cerrar_menu():
	hide()
	get_tree().paused = false

func cambiar_estado(nuevo_estado):
	estado_actual = nuevo_estado
	var paneles = contenedor_personajes.get_children()
	
	# 1. Apagamos "lo extra" por defecto
	if panel_categorias: panel_categorias.hide()
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn: btn.focus_mode = Control.FOCUS_NONE
	
	# 2. Encendemos solo lo que el estado actual necesita
	if estado_actual == EstadoMenu.PRINCIPAL:
		print("[MENÚ] Opciones Principales")
		btn_items.grab_focus()
		
	elif estado_actual == EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS:
		print("[MENÚ] Eligiendo Categoría")
		# Mostramos el mini-panel y ponemos el foco en "Consumibles"
		if panel_categorias: 
			panel_categorias.show()
			btn_consumibles.grab_focus()
			
			
	elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		print("[MENÚ] ¿Qué mochila vemos?")
		if panel_categorias: panel_categorias.show() # Se queda visible de fondo
		
		for i in range(paneles.size()):
			var btn = paneles[i].get_node_or_null("BtnSeleccionar")
			if btn and i < GlobalGame.party_actual.size():
				btn.focus_mode = Control.FOCUS_ALL
					
		var primer_btn = paneles[0].get_node_or_null("BtnSeleccionar")
		if primer_btn: primer_btn.grab_focus()
		
	elif estado_actual == EstadoMenu.VIENDO_INVENTARIO:
		print("[MENÚ] Navegando por el inventario grande")
		# No hace falta darle grab_focus aquí porque nuestra función
		# abrir_inventario_consumibles ya lo hace al final con _enfocar_primer_item()

# --- ACCIONES DE BOTONES (Rutas del Roadmap) ---

func _on_btn_items_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)

func _on_btn_consumibles_pressed():
	# Si son consumibles, hay que preguntar QUÉ personaje
	cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS)

func _on_btn_coleccion_pressed():
	# ¡FASE 4! Aquí saltaremos luego, no pregunta personaje
	print("[SISTEMA] Has seleccionado la Mochila de Colección Global")

func _on_btn_claves_pressed():
	# ¡FASE 4! Aquí saltaremos luego, no pregunta personaje
	print("[SISTEMA] Has seleccionado la Mochila de Objetos Clave Global")

func _on_personaje_seleccionado(indice: int):
	if estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		var personaje = GlobalGame.party_actual[indice]
		print("[SISTEMA] Abriendo panel grande para los consumibles de: ", personaje.nombre)
		abrir_inventario_consumibles(personaje)
		cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)

# (AQUÍ DEBE ESTAR TU FUNCION actualizar_menu() QUE NO BORRASTE)

func actualizar_menu():
	# --- ACTUALIZAR DINERO ---
	if lbl_whenes:
		lbl_whenes.text = "Whenes: " + str(GlobalGame.whenes_actuales)
	
	var paneles = contenedor_personajes.get_children()
	for i in range(paneles.size()):
		var panel = paneles[i]
		panel.show() 
		
		var nodo_fondo = panel.get_node_or_null("FondoPanel") as TextureRect
		var nodo_pose = panel.get_node_or_null("SpritePose") as TextureRect
		var btn_seleccionar = panel.get_node_or_null("BtnSeleccionar")
		
		if i < GlobalGame.party_actual.size():
			var heroe = GlobalGame.party_actual[i]
			
			panel.modulate = Color(1, 1, 1, 1)
			
			# Habilitamos su botón invisible
			if btn_seleccionar: btn_seleccionar.disabled = false
			
			# --- TEXTOS DE ESTADÍSTICAS (¡Restaurados!) ---
			panel.get_node("LblNombre").text = heroe.nombre
			panel.get_node("LblClase").text = heroe.clase
			panel.get_node("LblNivel").text = "Nv. " + str(heroe.nivel)
			
			panel.get_node("LblPV").text = "PV: " + str(heroe.pv_actuales)
			panel.get_node("LblPH").text = "PH: " + str(heroe.ph_actuales)
			panel.get_node("LblPT").text = "PT: " + str(heroe.pt_actuales)
			
			var exp_faltante = heroe.exp_necesaria_proximo_nivel - heroe.exp_actual
			panel.get_node("LblExp").text = "EXP: " + str(heroe.exp_actual) + " (Faltan: " + str(exp_faltante) + ")"
			
			var items_ocupados = 0
			for item in heroe.inventario:
				if item != null: items_ocupados += 1
			panel.get_node("LblInv").text = "Bolsillos: " + str(items_ocupados) + " / " + str(heroe.max_items)
			
			# --- LLENADO DE BARRAS VISUALES ---
			var barra_pv = panel.get_node_or_null("BarraPV")
			if barra_pv:
				barra_pv.max_value = heroe.pv_maximos
				barra_pv.value = heroe.pv_actuales
				
			var barra_ph = panel.get_node_or_null("BarraPH")
			if barra_ph:
				barra_ph.max_value = heroe.ph_maximos
				barra_ph.value = heroe.ph_actuales
				
			var barra_pt = panel.get_node_or_null("BarraPT")
			if barra_pt:
				barra_pt.max_value = heroe.pt_maximos
				barra_pt.value = heroe.pt_actuales
				
			var barra_exp = panel.get_node_or_null("BarraExp")
			if barra_exp:
				barra_exp.max_value = heroe.exp_necesaria_proximo_nivel
				barra_exp.value = heroe.exp_actual
			
			# --- CAPAS DE ARTE ---
			if nodo_fondo:
				if heroe.textura_panel != null:
					nodo_fondo.show()
					nodo_fondo.texture = heroe.textura_panel
				else:
					nodo_fondo.hide()
					
			if nodo_pose:
				if heroe.get("textura_pose_menu") != null and heroe.textura_pose_menu != null:
					nodo_pose.show()
					nodo_pose.texture = heroe.textura_pose_menu
				else:
					nodo_pose.hide() 
			
		else:
			# --- TRUCO FANTASMA ---
			panel.modulate = Color(1, 1, 1, 0)
			
			# Desactivamos el botón si no hay personaje
			if btn_seleccionar: btn_seleccionar.disabled = true
			
			if nodo_fondo: nodo_fondo.hide()
			if nodo_pose: nodo_pose.hide()

func abrir_inventario_consumibles(personaje: CharacterStats):
	personaje_viendo_inventario = personaje
	panel_gran_inventario.show() 
	
	# --- FIX PARA EL BUG DE NAVEGACIÓN (LOS FANTASMAS) ---
	for hijo in grid_items.get_children():
		grid_items.remove_child(hijo) # 1. Lo arrancamos del Grid INMEDIATAMENTE
		hijo.queue_free() # 2. Lo mandamos a borrar en paz
		
	var items_validos = 0
		
	# Recorrer el inventario real del personaje
	for item in personaje.inventario:
		if item == null: 
			continue # ¡Por si hay huecos vacíos en el array del inventario!
			
		items_validos += 1
		
		var btn_item = Button.new()
		
		# --- FIX PARA EL TAMAÑO (PROBLEMA 1) ---
		# Aumenta este Vector2 (ej. 96x96, 128x128) hasta que el botón se vea como quieres
		btn_item.custom_minimum_size = Vector2(200, 200) 
		
		if item.icono:
			btn_item.icon = item.icono
			btn_item.expand_icon = true # Obliga a la textura a llenar el espacio
			# Centra el icono para que no se vea raro al estirarse
			btn_item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER 
		else:
			btn_item.text = item.nombre.substr(0, 1) 
			
		# --- LA INTELIGENCIA DEL MENÚ ---
		btn_item.focus_entered.connect(_actualizar_detalles_item.bind(item, personaje))
		btn_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		grid_items.add_child(btn_item)
		
	# Si realmente hay ítems después de limpiar vacíos, enfocamos el primero
	if items_validos > 0:
		call_deferred("_enfocar_primer_item")
	else:
		_limpiar_detalles()

func _enfocar_primer_item():
	if grid_items.get_child_count() > 0:
		var primer_item = grid_items.get_child(0)
		primer_item.grab_focus()
		# TRUCO: Forzamos a que actualice el texto al instante, por si acaso Godot
		# se pone caprichoso y no detecta el cambio de foco la primera vez.
		primer_item.emit_signal("focus_entered")

# Esta es la función que se dispara solita cuando tocas un ítem
func _actualizar_detalles_item(item: Item, personaje: CharacterStats):
	lbl_nombre_item.text = item.nombre
	lbl_descripcion.text = item.descripcion
	textura_item_centro.texture = item.icono
	
	# Para la mano: Si tienes una textura de mano específica guardada en tu personaje (ej. personaje.textura_mano),
	# la asignarías así. Si usas una mano genérica, simplemente configúrala directo en el editor.
	# textura_mano.texture = personaje.textura_mano

func _limpiar_detalles():
	lbl_nombre_item.text = "Mochila vacía"
	lbl_descripcion.text = "No tienes objetos consumibles."
	textura_item_centro.texture = null
	
