extends Control

var posiciones_base_paneles: Dictionary = {}

func _ready():
	# Guardamos las posiciones Y iniciales un frame después para que Godot haya acomodado todo
	call_deferred("_guardar_posiciones_paneles")

func _guardar_posiciones_paneles():
	for panel in get_children():
		posiciones_base_paneles[panel] = panel.position.y

# ===== ACTUALIZACIÓN DE BARRAS =====
func actualizar_interfaz_party(party_jugador: Array, ui_ref: Node):
	var paneles = get_children()
	for i in range(paneles.size()):
		if i < party_jugador.size():
			var heroe = party_jugador[i]
			var panel = paneles[i]
			panel.show()

			panel.find_child("LblNombre").text = heroe.nombre
			var color_hex = "#" + heroe.color_interfaz.to_html(false)

			_actualizar_stat_visual(panel, "PV", heroe.pv_actuales, heroe.pv_maximos, color_hex)
			_actualizar_stat_visual(panel, "PH", heroe.ph_actuales, heroe.ph_maximos, color_hex)
			_actualizar_stat_visual(panel, "PT", heroe.pt_actuales, heroe.pt_maximos, color_hex)

			if heroe.get("textura_panel") and heroe.textura_panel != null:
				var style = StyleBoxTexture.new()
				style.texture = heroe.textura_panel
				panel.add_theme_stylebox_override("panel", style)
				panel.self_modulate = Color(1, 1, 1, 1)
			else:
				panel.remove_theme_stylebox_override("panel")

			_dibujar_estados_heroe(panel, heroe, ui_ref)
		else:
			paneles[i].hide()

func _actualizar_stat_visual(panel: Control, sigla: String, valor_actual: int, valor_max: int, color_hex: String):
	var lbl = panel.find_child("Lbl" + sigla)
	var barra = panel.find_child("Barra" + sigla)

	if barra:
		barra.max_value = valor_max
		if not barra.has_meta("animando"):
			barra.value = valor_actual

	if lbl:
		if lbl.has_method("set_use_bbcode"):
			lbl.bbcode_enabled = true

		var texto_actual = valor_actual

		if lbl.text != "":
			var texto_plano = lbl.get_parsed_text() if lbl.has_method("get_parsed_text") else lbl.text
			var numeros = texto_plano.replace(sigla, "").replace(":", "").strip_edges()
			if numeros.is_valid_int():
				texto_actual = numeros.to_int()

		if texto_actual != valor_actual:
			_animar_rolleo_generico(lbl, barra, sigla, texto_actual, valor_actual, color_hex)
		else:
			_set_stat_text(lbl, sigla, valor_actual, color_hex)

func _animar_rolleo_generico(lbl, barra, sigla: String, v_inicial: int, v_final: int, color_hex: String):
	var tween = get_tree().create_tween()
	if barra:
		barra.set_meta("animando", true)

	tween.tween_method(
		func(val):
			if lbl:
				_set_stat_text(lbl, sigla, int(val), color_hex)
			if barra:
				barra.value = val,
		float(v_inicial),
		float(v_final),
		0.5
	).set_trans(Tween.TRANS_LINEAR)

	if barra:
		tween.tween_callback(func(): barra.remove_meta("animando"))

func _set_stat_text(nodo, sigla: String, valor: int, color_hex: String):
	if nodo.has_method("get_parsed_text"):
		nodo.text = "[color=" + color_hex + "]" + sigla + "[/color] " + str(valor)
	else:
		nodo.text = sigla + " " + str(valor)

# ===== ESTADOS Y TURNOS =====
func _dibujar_estados_heroe(panel_heroe: Panel, heroe: CharacterStats, ui_ref: Node):
	var contenedor_estados = panel_heroe.get_node_or_null("CajaEstados")
	if not contenedor_estados:
		contenedor_estados = HBoxContainer.new()
		contenedor_estados.name = "CajaEstados"
		panel_heroe.add_child(contenedor_estados)
		contenedor_estados.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		contenedor_estados.alignment = BoxContainer.ALIGNMENT_BEGIN
		contenedor_estados.position = Vector2(15, 45)
		contenedor_estados.z_index = 1

	for hijo in contenedor_estados.get_children():
		hijo.queue_free()

	# Pedimos prestados los íconos del BattleUI (ui_ref)
	if heroe.niveles_stat["ataque"] > 0 and ui_ref.icon_atk_up:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_atk_up)
	elif heroe.niveles_stat["ataque"] < 0 and ui_ref.icon_atk_down:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_atk_down)

	if heroe.niveles_stat["defensa"] > 0 and ui_ref.icon_def_up:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_def_up)
	elif heroe.niveles_stat["defensa"] < 0 and ui_ref.icon_def_down:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_def_down)

	if heroe.niveles_stat["agilidad"] > 0 and ui_ref.icon_agi_up:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_agi_up)
	elif heroe.niveles_stat["agilidad"] < 0 and ui_ref.icon_agi_down:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_agi_down)

	if heroe.niveles_stat["suerte"] > 0 and ui_ref.icon_suerte_up:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_suerte_up)
	elif heroe.niveles_stat["suerte"] < 0 and ui_ref.icon_suerte_down:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_suerte_down)

	if heroe.turnos_provocacion > 0 and ui_ref.icon_provocacion:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_provocacion)
	if heroe.turnos_distraido > 0 and ui_ref.icon_distraido:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_distraido)
	if heroe.turnos_enamorado > 0 and ui_ref.icon_enamorado:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_enamorado)
	if heroe.esta_defendiendo and ui_ref.icon_defensa:
		_crear_icono_estado(contenedor_estados, ui_ref.icon_defensa)

func _crear_icono_estado(contenedor: Control, textura: Texture2D):
	var rect = TextureRect.new()
	rect.texture = textura
	rect.custom_minimum_size = Vector2(20, 20)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var bg = Panel.new()
	bg.show_behind_parent = true
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.self_modulate = Color(0, 0, 0, 0.6)
	rect.add_child(bg)

	contenedor.add_child(rect)

func animar_turno_activo(heroe_activo: CharacterStats, party_jugador: Array):
	var paneles = get_children()
	for i in range(paneles.size()):
		if i < party_jugador.size():
			var heroe = party_jugador[i]
			var panel = paneles[i]

			if not posiciones_base_paneles.has(panel):
				continue
			var y_base = posiciones_base_paneles[panel]

			var tween = get_tree().create_tween()

			if heroe == heroe_activo:
				tween.tween_property(panel, "position:y", y_base - 25, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(panel, "modulate", Color(1.1, 1.1, 1.1), 0.2)
			else:
				tween.tween_property(panel, "position:y", y_base, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(panel, "modulate", Color.WHITE, 0.2)

func actualizar_linea_turnos(combatientes: Array, turno_actual: int, party_jugador: Array, contenedor_turnos: Node):
	if not contenedor_turnos:
		return

	for hijo in contenedor_turnos.get_children():
		hijo.queue_free()

	var futuros_turnos = []
	for i in range(turno_actual, combatientes.size()):
		var c = combatientes[i]
		if c.pv_actuales > 0:
			futuros_turnos.append(c)

	for i in range(futuros_turnos.size()):
		var c = futuros_turnos[i]
		var nodo_visual = null

		if c.get("icono_timeline") and c.icono_timeline != null:
			var img = TextureRect.new()
			img.texture = c.icono_timeline
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.custom_minimum_size = Vector2(32, 32)
			nodo_visual = img
		else:
			var lbl = Label.new()
			var sigla = ""
			if party_jugador.has(c):
				sigla = c.nombre.substr(0, 2)
				lbl.modulate = Color("88ccff")
			else:
				sigla = "En" if not c.nombre.ends_with("2") else "E2"
				lbl.modulate = Color("ff6666")
			lbl.text = sigla
			nodo_visual = lbl

		if i == 0:
			nodo_visual.modulate = Color("ffff00")
		contenedor_turnos.add_child(nodo_visual)

		if i < futuros_turnos.size() - 1:
			var sep = Label.new()
			sep.text = ">"
			sep.modulate = Color(1, 1, 1, 0.5)
			contenedor_turnos.add_child(sep)
