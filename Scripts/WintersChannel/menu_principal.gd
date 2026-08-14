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

var personaje_viendo_inventario: CharacterStats = null

# --- MÁQUINA DE ESTADOS ---
enum EstadoMenu { PRINCIPAL, SELECCIONANDO_CATEGORIA_ITEMS, SELECCIONANDO_PJ_ITEMS, VIENDO_INVENTARIO }
var estado_actual = EstadoMenu.PRINCIPAL

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if panel_categorias: panel_categorias.hide() 
	if panel_gran_inventario: panel_gran_inventario.hide() 
	
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
	
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		
		if visible:
			if estado_actual == EstadoMenu.VIENDO_INVENTARIO:
				panel_gran_inventario.hide() 
				cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS) 
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
	
	# --- ¡NUEVO! Ocultar personajes si estamos viendo la mochila grande ---
	if estado_actual == EstadoMenu.VIENDO_INVENTARIO:
		contenedor_personajes.hide()
	else:
		contenedor_personajes.show()
		
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

# --- ACCIONES DE BOTONES ---

func _on_btn_items_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)

func _on_btn_consumibles_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS)

func _on_btn_coleccion_pressed():
	print("[SISTEMA] Has seleccionado la Mochila de Colección Global")

func _on_btn_claves_pressed():
	print("[SISTEMA] Has seleccionado la Mochila de Objetos Clave Global")

func _on_personaje_seleccionado(indice: int):
	if estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		var personaje = GlobalGame.party_actual[indice]
		print("[SISTEMA] Abriendo panel grande para los consumibles de: ", personaje.nombre)
		abrir_inventario_consumibles(personaje)
		cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)

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
func _on_item_pressed(item: Item, personaje: CharacterStats):
	print("[SISTEMA] Se pulsó 'Aceptar' sobre el ítem: ", item.nombre)
	# TODO: Aquí pondremos el código para instanciar/mostrar el mini-menú 
	# que pregunte: "¿En quién quieres usar " + item.nombre + "?"
