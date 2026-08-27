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
@onready var panel_gran_inventario = $PanelGranInventario
@onready var lbl_nombre_item = $PanelGranInventario/HBoxPrincipal/LadoDetalles/LblNombreItem
@onready var textura_mano = $PanelGranInventario/HBoxPrincipal/LadoDetalles/CajaIlustracion/TexturaMano
@onready var textura_item_centro = $PanelGranInventario/HBoxPrincipal/LadoDetalles/CajaIlustracion/TexturaItemCentro
@onready var lbl_descripcion = $PanelGranInventario/HBoxPrincipal/LadoDetalles/LblDescripcion
@onready var grid_items = $PanelGranInventario/HBoxPrincipal/ScrollMochila/GridItems
@onready var panel_subcat_coleccion = $PanelSubcategoriasColeccion
@onready var btn_cartas = $PanelSubcategoriasColeccion/VBox/BtnCartas
@onready var btn_fotos = $PanelSubcategoriasColeccion/VBox/BtnFotos
@onready var btn_skins = $PanelSubcategoriasColeccion/VBox/BtnSkins

# --- REFERENCIAS DEL CARRUSEL (FASE 2 Y 3) ---
@onready var panel_carrusel = $PanelCarruselCartas
@onready var retrato_carrusel = $PanelCarruselCartas/HBoxCarrusel/ZonaIzquierda/RetratoCarrusel
@onready var lbl_nombre_carrusel = $PanelCarruselCartas/HBoxCarrusel/ZonaIzquierda/LblNombreCarrusel
@onready var lbl_conteo_carrusel = $PanelCarruselCartas/HBoxCarrusel/ZonaIzquierda/LblConteoCartas
@onready var pista_movimiento = $PanelCarruselCartas/HBoxCarrusel/ZonaCartas/PistaMovimiento

# --- MEMORIA DEL CARRUSEL ---
var cartas_agrupadas: Dictionary = {}
var carrusel_personajes_base: Array = [] # Lista original ordenada (Ej: Jhosep, Romn)
var filas_infinitas: Array = [] # ¡El cilindro! La lista multiplicada muchas veces
var indice_carrusel_y: int = 0 # En qué fila (personaje) estamos de la lista infinita
var indices_carrusel_x: Dictionary = {} # En qué carta está cada personaje (Ej: {"Jhosep": 2})

# --- DISTANCIAS ---
const ESPACIO_Y = 220 
const ESPACIO_X = 170 # Ampliado un poquito para las cartas MEGA GRANDES
const CENTRO_PANTALLA_Y = 340 # <-- Empuja la carta activa hacia abajo (Ajusta a tu gusto)
const CENTRO_PANTALLA_X = 60  # <-- Empuja la carta activa a la derecha (Ajusta a tu gusto)

var personaje_viendo_inventario: CharacterStats = null
var item_a_usar: Item = null # <-- ¡NUEVA! Recuerda qué ítem seleccionaste

# --- MÁQUINA DE ESTADOS ---
enum EstadoMenu { 
	PRINCIPAL, 
	SELECCIONANDO_CATEGORIA_ITEMS, 
	SELECCIONANDO_PJ_ITEMS, 
	VIENDO_INVENTARIO, 
	SELECCIONANDO_OBJETIVO_ITEM,
	SELECCIONANDO_SUBCAT_COLECCION,
	VIENDO_CARRUSEL_CARTAS
}
var estado_actual = EstadoMenu.PRINCIPAL

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if panel_categorias: panel_categorias.hide() 
	if panel_gran_inventario: panel_gran_inventario.hide() 
	if panel_subcat_coleccion: panel_subcat_coleccion.hide()
	if panel_carrusel: panel_carrusel.hide()
	
	if btn_cartas: btn_cartas.pressed.connect(_on_btn_cartas_pressed)
	if btn_fotos: btn_fotos.pressed.connect(_on_btn_fotos_pressed)
	if btn_skins: btn_skins.pressed.connect(_on_btn_skins_pressed)
	if btn_items: btn_items.pressed.connect(_on_btn_items_pressed)
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
	
# --- CONTROLES DE DIRECCIÓN DEL CARRUSEL ---
	if visible and estado_actual == EstadoMenu.VIENDO_CARRUSEL_CARTAS:
		if not carrusel_personajes_base.is_empty():
			if event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				_verificar_bucle_infinito()
				indice_carrusel_y -= 1
				_verificar_bucle_infinito()
				_actualizar_carrusel_visual()
					
			elif event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_verificar_bucle_infinito()
				indice_carrusel_y += 1
				_verificar_bucle_infinito()
				_actualizar_carrusel_visual()
					
			elif event.is_action_pressed("ui_left"):
				get_viewport().set_input_as_handled()
				var pj_actual = filas_infinitas[indice_carrusel_y] 
				if indices_carrusel_x[pj_actual] > 0:
					indices_carrusel_x[pj_actual] -= 1
					_actualizar_carrusel_visual()
					
			elif event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				var pj_actual = filas_infinitas[indice_carrusel_y]
				if indices_carrusel_x[pj_actual] < 5: 
					indices_carrusel_x[pj_actual] += 1
					_actualizar_carrusel_visual()
	
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		
		if visible:
			# --- LA ESCALERA DE RETROCESO (Corregida y Limpia) ---
			
			# ¡NUEVO! Volver del carrusel al submenú de Colección
			if estado_actual == EstadoMenu.VIENDO_CARRUSEL_CARTAS:
				cambiar_estado(EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION)
			
			# 1. Si estamos a punto de curar a alguien, cancelamos y volvemos a la mochila
			elif estado_actual == EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM:
				cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)
				abrir_inventario_consumibles(personaje_viendo_inventario) 
				
			# 2. Si estamos en la mochila, la cerramos y volvemos a los personajes
			elif estado_actual == EstadoMenu.VIENDO_INVENTARIO:
				panel_gran_inventario.hide() 
				cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS) 
				
			# 3. Volver de las subcategorías a las categorías principales
			elif estado_actual == EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION:
				cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)
				
			# 4. Si estamos en los personajes, volvemos a las categorías
			elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
				cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)
				
			# 5. Si estamos en categorías, volvemos a las opciones principales
			elif estado_actual == EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS:
				cambiar_estado(EstadoMenu.PRINCIPAL)
				
			# 6. Salir del menú por completo
			else:
				cerrar_menu()
		else:
			abrir_menu()

func _verificar_bucle_infinito():
	var tam = carrusel_personajes_base.size()
	var teletransportado = false
	
	# Si estamos muy arriba, bajamos el cilindro
	if indice_carrusel_y <= tam * 2:
		indice_carrusel_y += tam * 4
		teletransportado = true
		
	# Si estamos muy abajo, subimos el cilindro
	elif indice_carrusel_y >= tam * 7:
		indice_carrusel_y -= tam * 4
		teletransportado = true
		
	# ¡EL SECRETO! Actualizamos los clones en 0 segundos antes de movernos
	if teletransportado:
		_actualizar_carrusel_visual(true)

func abrir_menu():
	show()
	actualizar_menu()
	get_tree().paused = true
	cambiar_estado(EstadoMenu.PRINCIPAL) 

func cerrar_menu():
	hide()
	get_tree().paused = false

func cambiar_estado(nuevo_estado):
	if panel_carrusel: panel_carrusel.hide()
	estado_actual = nuevo_estado
	
	# --- ¡NUEVO! Ocultar personajes si estamos viendo la mochila grande ---	
	if estado_actual == EstadoMenu.VIENDO_INVENTARIO:
		contenedor_personajes.hide()
	else:
		contenedor_personajes.show()
		
	var paneles = contenedor_personajes.get_children()
	
	# 1. Apagamos "lo extra" por defecto
	if panel_categorias: panel_categorias.hide()
	if panel_subcat_coleccion: panel_subcat_coleccion.hide()
	if panel_carrusel: panel_carrusel.hide()
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn: btn.focus_mode = Control.FOCUS_NONE
	
	# 2. Encendemos solo lo que el estado actual necesita
	if estado_actual == EstadoMenu.PRINCIPAL:
		print("[MENÚ] Opciones Principales")
		btn_items.grab_focus()
		
	elif estado_actual == EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS:
		print("[MENÚ] Eligiendo Categoría")
		if panel_categorias: 
			panel_categorias.show()
			btn_consumibles.grab_focus()
			
	elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		print("[MENÚ] ¿Qué mochila vemos?")
		if panel_categorias: panel_categorias.show() 
		
		for i in range(paneles.size()):
			var btn = paneles[i].get_node_or_null("BtnSeleccionar")
			if btn and i < GlobalGame.party_actual.size():
				btn.focus_mode = Control.FOCUS_ALL
					
		var primer_btn = paneles[0].get_node_or_null("BtnSeleccionar")
		if primer_btn: primer_btn.grab_focus()
		
	elif estado_actual == EstadoMenu.VIENDO_INVENTARIO:
		print("[MENÚ] Navegando por el inventario grande")
	
	# --- ¡NUEVO ESTADO! ---
	elif estado_actual == EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM:
		print("[MENÚ] ¿A quién le aplicamos el ítem?")
		
		# Ocultamos el inventario gigante y traemos de vuelta a los personajes
		panel_gran_inventario.hide()
		contenedor_personajes.show()
		
		for i in range(paneles.size()):
			var btn = paneles[i].get_node_or_null("BtnSeleccionar")
			if btn and i < GlobalGame.party_actual.size():
				btn.focus_mode = Control.FOCUS_ALL
					
		var primer_btn = paneles[0].get_node_or_null("BtnSeleccionar")
		if primer_btn: primer_btn.grab_focus()
			
	# --- ¡NUEVO ESTADO! ---
	elif estado_actual == EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION:
		print("[MENÚ] Eligiendo Subcategoría de Colección")
		if panel_categorias: panel_categorias.show()
		if panel_subcat_coleccion: 
			panel_subcat_coleccion.show()
			btn_cartas.grab_focus()
			
	# --- ¡NUEVO ESTADO: CARRUSEL! ---
	elif estado_actual == EstadoMenu.VIENDO_CARRUSEL_CARTAS:
		print("[MENÚ] Entrando al sistema de Carrusel...")
		contenedor_personajes.hide()
		if panel_categorias: panel_categorias.hide()
		if panel_subcat_coleccion: panel_subcat_coleccion.hide()
		if panel_carrusel: panel_carrusel.show()

# --- ACCIONES DE BOTONES ---

func _on_btn_items_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)

func _on_btn_consumibles_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS)

func _on_btn_coleccion_pressed():
	# Ahora en lugar del print, abrimos el sub-menú
	cambiar_estado(EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION)

# --- PLACEHOLDERS DE SUBCATEGORÍAS ---
func _on_btn_cartas_pressed():
	print("[SISTEMA] Ordenando barajas por personaje...")
	cartas_agrupadas.clear()
	
	for carta in GlobalGame.inventario_cartas:
		if carta == null: continue
		var dueño = carta.personaje_coleccion
		if not cartas_agrupadas.has(dueño):
			cartas_agrupadas[dueño] = []
		cartas_agrupadas[dueño].append(carta)
		
	abrir_carrusel()

func _on_btn_fotos_pressed():
	print("[SISTEMA] Se ha presionado la sección de FotosRoll")

func _on_btn_skins_pressed():
	print("[SISTEMA] Se ha presionado la sección de Skins (Aún no implementado)")

func _on_btn_claves_pressed():
	print("[SISTEMA] Has seleccionado la Mochila de Objetos Clave Global")

func _on_personaje_seleccionado(indice: int):
	if estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		var personaje = GlobalGame.party_actual[indice]
		abrir_inventario_consumibles(personaje)
		cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)
		
	# --- ¡AQUÍ SE USA EL OBJETO! ---
	elif estado_actual == EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM:
		var objetivo_seleccionado = GlobalGame.party_actual[indice]
		
		# 1. Aplicamos el efecto (El "null" evita que crashee buscando a la UI de Batalla)
		if item_a_usar.objetivo == "todos_aliados":
			for aliado in GlobalGame.party_actual:
				item_a_usar.usar(personaje_viendo_inventario, aliado, null)
		else:
			item_a_usar.usar(personaje_viendo_inventario, objetivo_seleccionado, null)
			
		# 2. Eliminamos la poción de la mochila del dueño
		personaje_viendo_inventario.inventario.erase(item_a_usar)
		
		# 3. ¡Magia! Actualizamos el menú completo para que las barras de Vida suban en tiempo real
		actualizar_menu()
		
		# 4. Comprobamos si nos quedan MÁS de esta misma poción para seguir curando
		var tiene_mas = false
		var siguiente_instancia = null
		
		for i in personaje_viendo_inventario.inventario:
			if i != null and i.nombre == item_a_usar.nombre:
				tiene_mas = true
				siguiente_instancia = i
				break
				
		if tiene_mas:
			# Preparamos la siguiente poción en el cañón para seguir curando a gusto
			item_a_usar = siguiente_instancia
		else:
			# Si ya no le quedan pociones, regresamos obligatoriamente a la mochila
			cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)
			abrir_inventario_consumibles(personaje_viendo_inventario) # Recarga los cuadritos

func actualizar_menu():
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
			if btn_seleccionar: btn_seleccionar.disabled = false
			
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
			panel.modulate = Color(1, 1, 1, 0)
			if btn_seleccionar: btn_seleccionar.disabled = true
			if nodo_fondo: nodo_fondo.hide()
			if nodo_pose: nodo_pose.hide()

func abrir_inventario_consumibles(personaje: CharacterStats):
	personaje_viendo_inventario = personaje
	panel_gran_inventario.show() 
	
	if grid_items:
		grid_items.columns = 4 
		grid_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid_items.add_theme_constant_override("h_separation", 8)
		grid_items.add_theme_constant_override("v_separation", 8)

	for hijo in grid_items.get_children():
		grid_items.remove_child(hijo)
		hijo.queue_free()
		
	var total_casillas_inventario = 16 
	var primer_boton_enfocable = null
		
	for i in range(total_casillas_inventario):
		var btn_item = Button.new()
		
		btn_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		btn_item.size_flags_vertical = Control.SIZE_EXPAND_FILL 
		btn_item.custom_minimum_size = Vector2(80, 90) 
		btn_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var ranura_desbloqueada = i < personaje.max_items
		
		if ranura_desbloqueada:
			var tiene_item = i < personaje.inventario.size() and personaje.inventario[i] != null
			
			if tiene_item:
				var item = personaje.inventario[i]
				
				var vbox = VBoxContainer.new()
				vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) 
				vbox.alignment = BoxContainer.ALIGNMENT_CENTER
				vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vbox.add_theme_constant_override("separation", 2)
				
				var tex_icono = TextureRect.new()
				tex_icono.custom_minimum_size = Vector2(96, 96) 
				tex_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
				if item.icono: tex_icono.texture = item.icono
				vbox.add_child(tex_icono)
				
				var lbl_nombre = Label.new()
				lbl_nombre.text = item.nombre
				lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_nombre.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
				lbl_nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				lbl_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lbl_nombre.add_theme_font_size_override("font_size", 20)
				vbox.add_child(lbl_nombre)
				
				btn_item.add_child(vbox)
				
				# --- NAVEGACIÓN ---
				btn_item.focus_entered.connect(_actualizar_detalles_item.bind(item, personaje))
				
				# --- ¡FASE 5.1! PLACEHOLDER DE USO DE ÍTEM ---
				btn_item.pressed.connect(_on_item_pressed.bind(item, personaje))
				
			else:
				btn_item.text = "Vacío"
				btn_item.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
				btn_item.focus_entered.connect(_limpiar_detalles)
				
			if primer_boton_enfocable == null:
				primer_boton_enfocable = btn_item
				
		else:
			btn_item.disabled = true
			btn_item.focus_mode = Control.FOCUS_NONE
			btn_item.modulate = Color(0.3, 0.3, 0.3, 1.0)
			
		grid_items.add_child(btn_item)
		
	if primer_boton_enfocable != null:
		call_deferred("_forzar_foco_inicial", primer_boton_enfocable)
	else:
		_limpiar_detalles()

func _forzar_foco_inicial(nodo_boton: Button):
	nodo_boton.grab_focus()
	nodo_boton.emit_signal("focus_entered")

func _actualizar_detalles_item(item: Item, personaje: CharacterStats):
	lbl_nombre_item.text = item.nombre
	lbl_descripcion.text = item.descripcion
	textura_item_centro.texture = item.icono

func _limpiar_detalles():
	lbl_nombre_item.text = "Mochila vacía"
	lbl_descripcion.text = "No tienes objetos consumibles."
	textura_item_centro.texture = null

# --- FASE 5: USO DE OBJETOS ---
# --- FASE 5: USO DE OBJETOS ---
func _on_item_pressed(item: Item, personaje: CharacterStats):
	if item.subcategoria == "Ofensivo":
		# ¡Alerta de uso indebido!
		lbl_descripcion.text = "¡No puedes usar un objeto ofensivo fuera de combate!"
		return
		
	if item.subcategoria == "Refuerzo":
		item_a_usar = item
		lbl_descripcion.text = "Selecciona a un aliado para aplicarle este objeto..."
		cambiar_estado(EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM)
		
# --- FASE 3: LÓGICA DEL CARRUSEL ---
func abrir_carrusel():
	# 1. ORDEN FIJO ABSOLUTO: Los 4 Protagonistas Siempre
	carrusel_personajes_base = ["Jhosep", "Romn", "Massi", "Thais"]
	
	# Le creamos una lista vacía a los protas que aún no tengan cartas
	# para que el juego no crashee y dibuje sus cartas oscurecidas
	for pj in carrusel_personajes_base:
		if not cartas_agrupadas.has(pj):
			cartas_agrupadas[pj] = []
			
	# Limpieza de la pista visual
	for hijo in pista_movimiento.get_children():
		pista_movimiento.remove_child(hijo)
		hijo.queue_free()
	indices_carrusel_x.clear()
	filas_infinitas.clear()
	
	# Inicializamos los cursores X en 0 para los 4 personajes
	for pj in carrusel_personajes_base:
		indices_carrusel_x[pj] = 0
		
	# TRUCO BUCLE INFINITO: Multiplicamos la lista de 4 unas 9 veces (36 filas)
	for i in range(9):
		filas_infinitas.append_array(carrusel_personajes_base)
		
	# Nos paramos exactamente en el bloque central (Esto caerá siempre en Jhosep)
	indice_carrusel_y = 4 * carrusel_personajes_base.size()
	
# 2. Generamos TODAS las filas clonadas
	for i in range(filas_infinitas.size()):
		var personaje_nombre = filas_infinitas[i]
		var cartas = cartas_agrupadas[personaje_nombre]
		
		var fila = Control.new()
		fila.name = "Fila_" + str(i) + "_" + personaje_nombre
		fila.position.y = i * ESPACIO_Y 
		fila.size = Vector2(140, 200) # <-- ¡NUEVA! Evita que nazca con tamaño 0x0
		fila.pivot_offset = Vector2(70, 100) 
		pista_movimiento.add_child(fila)
		
		# Dibujamos las 6 ranuras
		for j in range(6):
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(140, 200)
			tex.size = Vector2(140, 200) # <-- ¡NUEVA! Fuerza el tamaño real instantáneamente
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.position.x = j * ESPACIO_X
			
			if j < cartas.size():
				tex.texture = cartas[j].icono
			else:
				# Carta vacía/bloqueada
				tex.modulate = Color(0.1, 0.1, 0.1, 0.4)
				
			fila.add_child(tex)
			
	contenedor_personajes.hide()
	if panel_categorias: panel_categorias.hide()
	if panel_subcat_coleccion: panel_subcat_coleccion.hide()
	if panel_carrusel: panel_carrusel.show()
	
	cambiar_estado(EstadoMenu.VIENDO_CARRUSEL_CARTAS)
	

	call_deferred("_actualizar_carrusel_visual", true)

func _actualizar_carrusel_visual(instantaneo: bool = false):
	if carrusel_personajes_base.is_empty(): return
	
	var pj_actual = filas_infinitas[indice_carrusel_y]
	var cartas = cartas_agrupadas[pj_actual]
	
	lbl_nombre_carrusel.text = pj_actual
	lbl_conteo_carrusel.text = str(cartas.size()) + " / 6"
	
	retrato_carrusel.texture = null
	for heroe in GlobalGame.party_actual:
		if heroe.nombre == pj_actual:
			retrato_carrusel.texture = heroe.textura_panel
			break
			
	var tween
	if not instantaneo:
		tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var tiempo_anim = 0.0 if instantaneo else 0.25
	
	# 1. Mover la Pista con el OFFSET para que no toque el techo
	var target_y = (-indice_carrusel_y * ESPACIO_Y) + CENTRO_PANTALLA_Y
	
	if instantaneo:
		pista_movimiento.position.y = target_y
	else:
		tween.tween_property(pista_movimiento, "position:y", target_y, tiempo_anim)
	
	# 2. Escalar y mover cada fila individual
	for i in range(filas_infinitas.size()):
		var fila = pista_movimiento.get_child(i)
		var nombre_fila = filas_infinitas[i]
		
		var distancia_al_centro = abs(i - indice_carrusel_y)
		var target_x = (-indices_carrusel_x[nombre_fila] * ESPACIO_X) + CENTRO_PANTALLA_X
		
		if distancia_al_centro == 0:
			if instantaneo:
				fila.scale = Vector2(1.2, 1.2)
				fila.modulate = Color(1, 1, 1, 1.0)
				fila.position.x = target_x
			else:
				tween.tween_property(fila, "scale", Vector2(1.2, 1.2), tiempo_anim)
				tween.tween_property(fila, "modulate", Color(1, 1, 1, 1.0), tiempo_anim)
				tween.tween_property(fila, "position:x", target_x, tiempo_anim)
				
		elif distancia_al_centro == 1:
			if instantaneo:
				fila.scale = Vector2(0.7, 0.7)
				fila.modulate = Color(1, 1, 1, 0.4)
				fila.position.x = target_x
			else:
				tween.tween_property(fila, "scale", Vector2(0.7, 0.7), tiempo_anim)
				tween.tween_property(fila, "modulate", Color(1, 1, 1, 0.4), tiempo_anim)
				tween.tween_property(fila, "position:x", target_x, tiempo_anim)
				
		else:
			if instantaneo:
				fila.scale = Vector2(0.5, 0.5)
				fila.modulate = Color(1, 1, 1, 0.0)
				fila.position.x = target_x
			else:
				tween.tween_property(fila, "scale", Vector2(0.5, 0.5), tiempo_anim)
				tween.tween_property(fila, "modulate", Color(1, 1, 1, 0.0), tiempo_anim)
				tween.tween_property(fila, "position:x", target_x, tiempo_anim)
