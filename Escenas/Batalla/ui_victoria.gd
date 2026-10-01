extends Panel

signal inversion_completada
signal heroe_elegido_para_item(heroe: CharacterStats)

@onready var contenedor_exp_heroes = $ContenedorExpHeroes

@export var contenedor_botin: VBoxContainer
@export var icono_whenes: Texture2D

var panel_reparto: Panel
var vbox_reparto: VBoxContainer
var ultimo_stat_enfocado: String = ""
var labels_estadisticas_heroes: Dictionary = {}

var panel_inversion: Panel
var heroe_inv_actual: CharacterStats
var recuadros_heroes: Dictionary = {}

func _ready():
	hide()
	
	# --- MENÚ DE INVERSIÓN (Mudado aquí) ---
	panel_inversion = Panel.new()
	panel_inversion.hide()
	panel_inversion.custom_minimum_size = Vector2(480, 300)
	panel_inversion.z_index = 100

	var style_inv = StyleBoxFlat.new()
	style_inv.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	style_inv.border_color = Color(0.8, 0.6, 0.1, 1.0)
	style_inv.border_width_left = 4
	style_inv.border_width_right = 4
	style_inv.border_width_top = 4
	style_inv.border_width_bottom = 4
	panel_inversion.add_theme_stylebox_override("panel", style_inv)
	add_child(panel_inversion)
	
	# --- MENÚ DE REPARTO DE ITEMS (Mudado aquí) ---
	panel_reparto = Panel.new()
	panel_reparto.hide()
	panel_reparto.custom_minimum_size = Vector2(500, 220)
	panel_reparto.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var style_rep = style_inv.duplicate() 
	style_rep.border_color = Color(0.2, 0.8, 0.4, 1.0) 
	panel_reparto.add_theme_stylebox_override("panel", style_rep)
	panel_reparto.z_index = 105
	add_child(panel_reparto)

	vbox_reparto = VBoxContainer.new()
	vbox_reparto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox_reparto.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_reparto.add_theme_constant_override("separation", 20)
	panel_reparto.add_child(vbox_reparto)

# ===== PANTALLA DE VICTORIA =====
func mostrar_pantalla_victoria(party: Array, exp_total: int, niveles_previos: Dictionary, whenes_total: int = 0, items_ganados: Array = []):
	show()
	recuadros_heroes.clear()
	labels_estadisticas_heroes.clear()

	for hijo in contenedor_exp_heroes.get_children():
		hijo.queue_free()

	for heroe in party:
		if heroe.pv_actuales > 0:
			var recuadro = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
			style.border_color = Color(0.8, 0.8, 0.8, 1.0)
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.content_margin_top = 10
			style.content_margin_bottom = 10
			style.content_margin_left = 20
			style.content_margin_right = 20

			recuadro.add_theme_stylebox_override("panel", style)
			recuadro.custom_minimum_size = Vector2(850, 140)

			recuadros_heroes[heroe] = recuadro
			labels_estadisticas_heroes[heroe] = {}

			var hbox_principal = HBoxContainer.new()
			hbox_principal.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_principal.add_theme_constant_override("separation", 35)
			recuadro.add_child(hbox_principal)

			# Retrato
			var retrato = TextureRect.new()
			retrato.texture = heroe.textura_panel if heroe.get("textura_panel") else heroe.retrato_base
			retrato.custom_minimum_size = Vector2(110, 110)
			retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox_principal.add_child(retrato)

			# Textos principales
			var vbox_textos = VBoxContainer.new()
			vbox_textos.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox_textos.custom_minimum_size = Vector2(200, 0)
			hbox_principal.add_child(vbox_textos)

			var lbl_nombre = Label.new()
			lbl_nombre.text = heroe.nombre
			lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_nombre.add_theme_font_size_override("font_size", 24)
			vbox_textos.add_child(lbl_nombre)

			var nivel_viejo = niveles_previos[heroe]
			var nivel_nuevo = heroe.nivel

			var lbl_nivel = Label.new()
			lbl_nivel.text = "Nivel: " + str(nivel_viejo)
			lbl_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_nivel.add_theme_font_size_override("font_size", 18)
			vbox_textos.add_child(lbl_nivel)

			var exp_real = int(exp_total * heroe.tasa_experiencia)
			var lbl_exp = Label.new()
			lbl_exp.text = "+" + str(exp_real) + " EXP"
			lbl_exp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_exp.add_theme_font_size_override("font_size", 20)
			lbl_exp.add_theme_color_override("font_color", Color("aaffaa"))
			vbox_textos.add_child(lbl_exp)

			var lbl_levelup = Label.new()
			lbl_levelup.text = "¡SUBIÓ DE NIVEL!"
			lbl_levelup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_levelup.add_theme_font_size_override("font_size", 16)
			lbl_levelup.add_theme_color_override("font_color", Color("ffff55"))
			lbl_levelup.hide()
			vbox_textos.add_child(lbl_levelup)

			var sep = VSeparator.new()
			hbox_principal.add_child(sep)

			var grid_stats = GridContainer.new()
			grid_stats.columns = 3
			grid_stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			grid_stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			grid_stats.add_theme_constant_override("h_separation", 30)
			grid_stats.add_theme_constant_override("v_separation", 8)
			hbox_principal.add_child(grid_stats)

			var estadisticas_a_mostrar = [
				{"nombre": "PV Max", "clave": "pv_maximos", "valor": heroe.pv_maximos},
				{"nombre": "PH Max", "clave": "ph_maximos", "valor": heroe.ph_maximos},
				{"nombre": "Ataque", "clave": "ataque", "valor": heroe.ataque},
				{"nombre": "Defensa", "clave": "defensa", "valor": heroe.defensa},
				{"nombre": "Agilid.", "clave": "agilidad", "valor": heroe.agilidad},
				{"nombre": "Suerte", "clave": "suerte", "valor": heroe.suerte}
			]

			for stat in estadisticas_a_mostrar:
				var hbox_stat = HBoxContainer.new()
				var lbl_nombre_stat = Label.new()
				lbl_nombre_stat.text = stat["nombre"] + ":"
				lbl_nombre_stat.add_theme_font_size_override("font_size", 15)
				lbl_nombre_stat.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

				var lbl_valor_stat = Label.new()
				lbl_valor_stat.text = str(stat["valor"])
				lbl_valor_stat.add_theme_font_size_override("font_size", 16)
				lbl_valor_stat.add_theme_color_override("font_color", Color.WHITE)

				labels_estadisticas_heroes[heroe][stat["clave"]] = lbl_valor_stat

				hbox_stat.add_child(lbl_nombre_stat)
				hbox_stat.add_child(lbl_valor_stat)
				grid_stats.add_child(hbox_stat)

			contenedor_exp_heroes.add_child(recuadro)

			var tween = get_tree().create_tween().bind_node(lbl_exp)
			var actualizar_texto = func(val):
				if is_instance_valid(lbl_exp):
					lbl_exp.text = "+" + str(int(val)) + " EXP"

			tween.tween_method(actualizar_texto, 0.0, float(exp_real), 1.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

			if nivel_nuevo > nivel_viejo:
				tween.tween_callback(func():
					lbl_levelup.show()
					lbl_nivel.text = "Nivel: " + str(nivel_viejo) + " -> " + str(nivel_nuevo)
					var tween_lvl = get_tree().create_tween()
					for i in range(4):
						tween_lvl.tween_property(lbl_levelup, "modulate", Color(2.0, 2.0, 2.0) if i%2==0 else Color.WHITE, 0.15)
				).set_delay(0.2)

	if contenedor_botin:
		for hijo in contenedor_botin.get_children():
			hijo.queue_free()

		var lbl_titulo_botin = Label.new()
		lbl_titulo_botin.text = "¡Botín Obtenido!"
		lbl_titulo_botin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_titulo_botin.add_theme_font_size_override("font_size", 44)
		lbl_titulo_botin.add_theme_color_override("font_color", Color("ffffff"))
		contenedor_botin.add_child(lbl_titulo_botin)

		var grid_botin = GridContainer.new()
		grid_botin.columns = 3
		grid_botin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid_botin.add_theme_constant_override("h_separation", 15)
		grid_botin.add_theme_constant_override("v_separation", 15)
		contenedor_botin.add_child(grid_botin)

		var style_slot = StyleBoxFlat.new()
		style_slot.bg_color = Color(0.2, 0.2, 0.25, 0.9)
		style_slot.border_color = Color(0.5, 0.5, 0.5, 1.0)
		style_slot.border_width_left = 2
		style_slot.border_width_right = 2
		style_slot.border_width_top = 2
		style_slot.border_width_bottom = 2
		style_slot.content_margin_top = 10
		style_slot.content_margin_bottom = 10
		style_slot.content_margin_left = 10
		style_slot.content_margin_right = 10

		var slot_whenes = PanelContainer.new()
		slot_whenes.add_theme_stylebox_override("panel", style_slot)
		slot_whenes.custom_minimum_size = Vector2(90, 90)
		var vbox_w = VBoxContainer.new()
		vbox_w.alignment = BoxContainer.ALIGNMENT_CENTER

		if icono_whenes:
			var tex_w = TextureRect.new()
			tex_w.texture = icono_whenes
			tex_w.custom_minimum_size = Vector2(32, 32)
			tex_w.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_w.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox_w.add_child(tex_w)

		var lbl_w_cant = Label.new()
		lbl_w_cant.text = str(whenes_total) + " W"
		lbl_w_cant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_w_cant.add_theme_color_override("font_color", Color("ffffaa"))
		vbox_w.add_child(lbl_w_cant)

		slot_whenes.add_child(vbox_w)
		grid_botin.add_child(slot_whenes)

		for item in items_ganados:
			var slot_item = PanelContainer.new()
			slot_item.add_theme_stylebox_override("panel", style_slot)
			slot_item.custom_minimum_size = Vector2(90, 90)

			var vbox_i = VBoxContainer.new()
			vbox_i.alignment = BoxContainer.ALIGNMENT_CENTER

			if item.get("icono") and item.icono != null:
				var tex_i = TextureRect.new()
				tex_i.texture = item.icono
				tex_i.custom_minimum_size = Vector2(32, 32)
				tex_i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				vbox_i.add_child(tex_i)

			var lbl_i_nom = Label.new()
			lbl_i_nom.text = item.nombre.left(8) + "." if item.get("nombre") and item.nombre.length() > 8 else (item.nombre if item.get("nombre") else "Item")
			lbl_i_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_i_nom.add_theme_font_size_override("font_size", 12)
			vbox_i.add_child(lbl_i_nom)

			slot_item.add_child(vbox_i)
			grid_botin.add_child(slot_item)

# ===== SISTEMA DE INVERSIÓN DE PUNTOS =====
func abrir_menu_inversion(heroe: CharacterStats):
	heroe_inv_actual = heroe
	ultimo_stat_enfocado = ""
	panel_inversion.show()
	actualizar_menu_inversion()

	await get_tree().process_frame

	if recuadros_heroes.has(heroe):
		var recuadro_heroe = recuadros_heroes[heroe]
		var pos_x = recuadro_heroe.global_position.x + recuadro_heroe.size.x + 40
		var pos_y = recuadro_heroe.global_position.y - (panel_inversion.size.y / 2) + (recuadro_heroe.size.y / 2)
		panel_inversion.global_position = Vector2(pos_x, pos_y)

func actualizar_menu_inversion():
	for hijo in panel_inversion.get_children():
		hijo.queue_free()

	if heroe_inv_actual.puntos_estadisticas <= 0:
		panel_inversion.hide()
		inversion_completada.emit()
		return

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel_inversion.add_child(vbox)

	var lbl_titulo = Label.new()
	lbl_titulo.text = "¡" + heroe_inv_actual.nombre + " se hace más fuerte!\nPuntos Restantes: " + str(heroe_inv_actual.puntos_estadisticas)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	lbl_titulo.add_theme_color_override("font_color", Color("ffffaa"))
	vbox.add_child(lbl_titulo)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 15)
	vbox.add_child(grid)

	var stats = [
		{"nombre": "PV Máximos", "clave": "pv_maximos", "incremento": 5, "actual": heroe_inv_actual.pv_maximos},
		{"nombre": "PH Máximos", "clave": "ph_maximos", "incremento": 5, "actual": heroe_inv_actual.ph_maximos},
		{"nombre": "Ataque", "clave": "ataque", "incremento": 1, "actual": heroe_inv_actual.ataque},
		{"nombre": "Defensa", "clave": "defensa", "incremento": 1, "actual": heroe_inv_actual.defensa},
		{"nombre": "Agilidad", "clave": "agilidad", "incremento": 1, "actual": heroe_inv_actual.agilidad},
		{"nombre": "Suerte", "clave": "suerte", "incremento": 1, "actual": heroe_inv_actual.suerte}
	]

	var primer_boton = null
	var boton_a_enfocar = null

	for stat in stats:
		var btn = Button.new()
		btn.text = stat["nombre"] + "\n" + str(stat["actual"]) + " -> " + str(stat["actual"] + stat["incremento"])
		btn.custom_minimum_size = Vector2(180, 50)
		btn.pressed.connect(func(): _invertir_punto(stat["clave"], stat["incremento"]))
		grid.add_child(btn)

		if primer_boton == null:
			primer_boton = btn
		if stat["clave"] == ultimo_stat_enfocado:
			boton_a_enfocar = btn

	if boton_a_enfocar:
		boton_a_enfocar.grab_focus()
	elif primer_boton:
		primer_boton.grab_focus()

func _invertir_punto(clave_stat: String, cantidad: int):
	ultimo_stat_enfocado = clave_stat
	heroe_inv_actual.set(clave_stat, heroe_inv_actual.get(clave_stat) + cantidad)

	if clave_stat == "pv_maximos":
		heroe_inv_actual.pv_actuales += cantidad
	elif clave_stat == "ph_maximos":
		heroe_inv_actual.ph_actuales += cantidad

	heroe_inv_actual.puntos_estadisticas -= 1

	if labels_estadisticas_heroes.has(heroe_inv_actual) and labels_estadisticas_heroes[heroe_inv_actual].has(clave_stat):
		var lbl_stat_tarjeta = labels_estadisticas_heroes[heroe_inv_actual][clave_stat]
		lbl_stat_tarjeta.text = str(heroe_inv_actual.get(clave_stat))

		var tween = get_tree().create_tween()
		tween.tween_property(lbl_stat_tarjeta, "modulate", Color("55ff55"), 0.1)
		tween.tween_property(lbl_stat_tarjeta, "modulate", Color.WHITE, 0.4)

	actualizar_menu_inversion()

# ===== SISTEMA DE REPARTO DE OBJETOS =====
func abrir_menu_reparto(item: Item, party: Array):
	panel_reparto.show()
	
	for hijo in vbox_reparto.get_children():
		hijo.queue_free()

	var lbl_titulo = Label.new()
	lbl_titulo.text = "¿En qué bolsillo guardas:\n" + item.nombre + "?"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	lbl_titulo.add_theme_color_override("font_color", Color("aaffaa"))
	vbox_reparto.add_child(lbl_titulo)

	if item.icono != null:
		var tex = TextureRect.new()
		tex.texture = item.icono
		tex.custom_minimum_size = Vector2(48, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox_reparto.add_child(tex)

	var hbox_botones = HBoxContainer.new()
	hbox_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_botones.add_theme_constant_override("separation", 15)
	vbox_reparto.add_child(hbox_botones)

	var primer_boton = null

	for heroe in party:
		if heroe.pv_actuales > 0:
			var btn = Button.new()
			btn.text = heroe.nombre
			btn.custom_minimum_size = Vector2(100, 45)
			btn.focus_mode = Control.FOCUS_ALL
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			btn.pressed.connect(func():
				panel_reparto.hide()
				heroe_elegido_para_item.emit(heroe)
			)
			
			hbox_botones.add_child(btn)

			if primer_boton == null:
				primer_boton = btn

	if primer_boton != null:
		primer_boton.call_deferred("grab_focus")
