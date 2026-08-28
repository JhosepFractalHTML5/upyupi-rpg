extends Control

# Le avisamos al menú principal qué objeto queremos usar
signal item_seleccionado_para_uso(item: Item)

# --- REFERENCIAS INTERNAS ---
@onready var lbl_nombre_item = $HBoxPrincipal/LadoDetalles/LblNombreItem
@onready var textura_mano = $HBoxPrincipal/LadoDetalles/CajaIlustracion/TexturaMano
@onready var textura_item_centro = $HBoxPrincipal/LadoDetalles/CajaIlustracion/TexturaItemCentro
@onready var lbl_descripcion = $HBoxPrincipal/LadoDetalles/LblDescripcion
@onready var grid_items = $HBoxPrincipal/ScrollMochila/GridItems

func abrir(personaje: CharacterStats):
	show() 
	
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
				btn_item.pressed.connect(_on_item_pressed.bind(item)) # ¡Llamamos al evento interno!
				
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

func _on_item_pressed(item: Item):
	if item.subcategoria == "Ofensivo":
		lbl_descripcion.text = "¡No puedes usar un objeto ofensivo fuera de combate!"
		return
		
	if item.subcategoria == "Refuerzo":
		lbl_descripcion.text = "Selecciona a un aliado para aplicarle este objeto..."
		# ¡Le gritamos al menú principal que queremos curar a alguien!
		emit_signal("item_seleccionado_para_uso", item)
