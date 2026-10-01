extends Panel

@onready var grid_items = $GridItems
@onready var grid_habilidades = $GridHabilidades

@export_category("Iconos de Interfaz")
@export var icono_bolsillo_vacio: Texture2D
@export var icono_ph: Texture2D
@export var icono_pt: Texture2D

# ===== INVENTARIO =====
func actualizar_inventario(atacante: CharacterStats, manager: Node, ui_ref: Node):
	grid_items.show()
	for hijo in grid_items.get_children():
		hijo.queue_free()

	for i in range(atacante.max_items):
		var btn = Button.new()
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.custom_minimum_size = Vector2(100, 100)
		btn.size = Vector2(100, 100)

		var rect_icono = TextureRect.new()
		rect_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect_icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var lbl_nombre = Label.new()
		lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_nombre.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl_nombre.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)

		var estilo_texto = LabelSettings.new()
		estilo_texto.font_size = 12
		estilo_texto.outline_size = 4
		estilo_texto.outline_color = Color.BLACK
		lbl_nombre.label_settings = estilo_texto

		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_meta("es_valido", false)

		if i < atacante.inventario.size() and atacante.inventario[i] != null:
			var item = atacante.inventario[i]
			rect_icono.texture = item.icono
			lbl_nombre.text = item.nombre

			btn.set_meta("es_valido", true)
			btn.set_meta("desc_item", item.descripcion)
			btn.focus_entered.connect(func():
				if manager.seleccionando_item:
					ui_ref.mostrar_descripcion_item(btn.get_meta("desc_item"))
			)
			btn.pressed.connect(manager._seleccionar_item.bind(item))
		else:
			lbl_nombre.text = "Vacío"
			lbl_nombre.modulate.a = 0.5
			if icono_bolsillo_vacio:
				rect_icono.texture = icono_bolsillo_vacio
				rect_icono.modulate.a = 0.3

		btn.add_child(rect_icono)
		btn.add_child(lbl_nombre)
		grid_items.add_child(btn)

# ===== HABILIDADES =====
func actualizar_habilidades(atacante: CharacterStats, manager: Node, ui_ref: Node):
	grid_habilidades.show()
	grid_habilidades.custom_minimum_size = Vector2(421, 230)
	grid_habilidades.size = Vector2(421, 230)
	grid_habilidades.columns = 2

	for hijo in grid_habilidades.get_children():
		hijo.queue_free()

	var claves_desbloqueo = [
		atacante.item_clave_hab_1, atacante.item_clave_hab_2,
		atacante.item_clave_hab_3, atacante.item_clave_hab_4,
		atacante.item_clave_hab_5, atacante.item_clave_hab_6
	]

	var max_activas = 2
	if atacante.get("max_habilidades_activas") != null:
		max_activas = atacante.max_habilidades_activas

	for i in range(4):
		var btn = Button.new()
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.custom_minimum_size = Vector2(200, 60)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_meta("es_valida", false)

		if i >= max_activas:
			btn.modulate = Color(1, 1, 1, 0)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_habilidades.add_child(btn)
			continue

		var hbox_principal = HBoxContainer.new()
		hbox_principal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox_principal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_principal.alignment = BoxContainer.ALIGNMENT_CENTER

		var rect_icon_hab = TextureRect.new()
		rect_icon_hab.custom_minimum_size = Vector2(60, 60)
		rect_icon_hab.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect_icon_hab.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect_icon_hab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_principal.add_child(rect_icon_hab)

		var vbox_textos = VBoxContainer.new()
		vbox_textos.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_textos.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var lbl_nombre = Label.new()
		lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_nombre.add_theme_font_size_override("font_size", 12)
		vbox_textos.add_child(lbl_nombre)

		var hab = null
		if i < atacante.habilidades_disponibles.size():
			hab = atacante.habilidades_disponibles[i]

		if hab != null and claves_desbloqueo[i] == true:
			btn.set_meta("es_valida", true)
			btn.set_meta("desc_hab", hab.descripcion)

			if hab.get("icono") and hab.icono != null:
				rect_icon_hab.texture = hab.icono

			if hab.get("fondo_panel") and hab.fondo_panel != null:
				var style_normal = StyleBoxTexture.new()
				style_normal.texture = hab.fondo_panel
				btn.add_theme_stylebox_override("normal", style_normal)
				btn.add_theme_stylebox_override("disabled", style_normal)

				var style_focus = style_normal.duplicate()
				style_focus.modulate_color = Color(1.2, 1.2, 1.2)
				btn.add_theme_stylebox_override("focus", style_focus)
				btn.add_theme_stylebox_override("hover", style_focus)

			lbl_nombre.text = hab.nombre

			var turnos_cd = atacante.cooldowns_actuales[hab] if atacante.cooldowns_actuales.has(hab) else 0
			var hbox_costos = HBoxContainer.new()
			hbox_costos.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_costos.mouse_filter = Control.MOUSE_FILTER_IGNORE

			if turnos_cd > 0:
				var lbl_cd = Label.new()
				lbl_cd.text = "CD: " + str(turnos_cd)
				lbl_cd.modulate = Color(1, 0.5, 0.5)
				lbl_cd.add_theme_font_size_override("font_size", 10)
				hbox_costos.add_child(lbl_cd)
			elif atacante.turnos_distraido > 0 and hab.es_ataque_fuerte:
				var lbl_bloq = Label.new()
				lbl_bloq.text = "BLOQUEADO"
				lbl_bloq.modulate = Color(0.8, 0.4, 0.4)
				lbl_bloq.add_theme_font_size_override("font_size", 10)
				hbox_costos.add_child(lbl_bloq)
			else:
				if hab.costo_ph > 0:
					var lbl_ph = Label.new()
					lbl_ph.text = str(hab.costo_ph)
					lbl_ph.add_theme_font_size_override("font_size", 10)
					hbox_costos.add_child(lbl_ph)
					if icono_ph:
						var tex_ph = TextureRect.new()
						tex_ph.texture = icono_ph
						tex_ph.custom_minimum_size = Vector2(12, 12)
						tex_ph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						tex_ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
						hbox_costos.add_child(tex_ph)

				if hab.costo_ph > 0 and hab.costo_pt > 0:
					var lbl_sep = Label.new()
					lbl_sep.text = "|"
					lbl_sep.add_theme_font_size_override("font_size", 10)
					hbox_costos.add_child(lbl_sep)

				if hab.costo_pt > 0:
					var lbl_pt = Label.new()
					lbl_pt.text = str(hab.costo_pt)
					lbl_pt.add_theme_font_size_override("font_size", 10)
					hbox_costos.add_child(lbl_pt)
					if icono_pt:
						var tex_pt = TextureRect.new()
						tex_pt.texture = icono_pt
						tex_pt.custom_minimum_size = Vector2(12, 12)
						tex_pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						tex_pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
						hbox_costos.add_child(tex_pt)

			vbox_textos.add_child(hbox_costos)

			btn.focus_entered.connect(func():
				if manager.accion_pendiente == "HABILIDAD_MENU":
					ui_ref.mostrar_descripcion_item(btn.get_meta("desc_hab"))
			)
			btn.pressed.connect(manager._seleccionar_habilidad.bind(hab))
		else:
			lbl_nombre.text = "- Vacío -"
			lbl_nombre.modulate.a = 0.5
			if icono_bolsillo_vacio:
				rect_icon_hab.texture = icono_bolsillo_vacio
				rect_icon_hab.modulate.a = 0.3

		hbox_principal.add_child(vbox_textos)
		btn.add_child(hbox_principal)
		grid_habilidades.add_child(btn)
