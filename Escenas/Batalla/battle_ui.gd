extends CanvasLayer
class_name BattleUI

# ===== REFERENCIAS A NODES =====
@onready var menu_acciones = $MenuAcciones
@onready var btn_atacar = $MenuAcciones/BtnAtacar
@onready var btn_defender = $MenuAcciones/BtnDefender
@onready var btn_habilidades = $MenuAcciones/BtnHabilidades
@onready var btn_items = $MenuAcciones/BtnItems
@onready var btn_huir = $MenuAcciones/BtnHuir
@onready var texto_log = $PanelLog/TextoLog
@onready var contenedor_party = $ContenedorParty
@onready var contenedor_enemigos = $ContenedorEnemigos
@onready var retrato_activo = $MenuAcciones/RetratoActivo
@onready var panel_accion = $PanelAccion
@onready var lbl_narrativa = $PanelAccion/VBox/LblNarrativa
@onready var grid_habilidades = $PanelLog/GridHabilidades
@onready var contenedor_turnos = $ContenedorTurnos
@onready var grid_items = $PanelLog/GridItems
@onready var panel_victoria = $PanelVictoria
@onready var contenedor_exp_heroes = $PanelVictoria/ContenedorExpHeroes

@export var contenedor_botin: VBoxContainer

# ===== ICONOS DE INTERFAZ =====
@export_category("Iconos de Interfaz")
@export var icono_bolsillo_vacio: Texture2D
@export var icono_ph: Texture2D
@export var icono_pt: Texture2D
@export var icono_pv: Texture2D
@export var icono_whenes: Texture2D

# ===== ICONOS DE ESTADOS =====
@export_category("Iconos de Estados Alterados")
@export var icon_atk_up: Texture2D
@export var icon_atk_down: Texture2D
@export var icon_def_up: Texture2D
@export var icon_def_down: Texture2D
@export var icon_agi_up: Texture2D
@export var icon_agi_down: Texture2D
@export var icon_suerte_up: Texture2D
@export var icon_suerte_down: Texture2D
@export var icon_provocacion: Texture2D
@export var icon_distraido: Texture2D
@export var icon_defensa: Texture2D

# ===== VARIABLES GLOBALES =====
var posiciones_base_paneles: Dictionary = {}
signal inversion_completada
var ultimo_stat_enfocado: String = ""
var labels_estadisticas_heroes: Dictionary = {}

var panel_inversion: Panel
var heroe_inv_actual: CharacterStats
var recuadros_heroes: Dictionary = {}

# ===== INICIALIZACIÓN =====
func _ready():
	panel_victoria.hide()
	menu_acciones.show()
	panel_accion.show()

	var botones_menu = [btn_atacar, btn_defender, btn_habilidades, btn_items, btn_huir]
	for btn in botones_menu:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	call_deferred("_guardar_posiciones_paneles")

	# Crear menú de inversión flotante
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

func _guardar_posiciones_paneles():
	for panel in contenedor_party.get_children():
		posiciones_base_paneles[panel] = panel.position.y

func set_menu_activo(activo: bool):
	btn_atacar.disabled = not activo
	btn_defender.disabled = not activo
	btn_habilidades.disabled = not activo
	btn_items.disabled = not activo
	btn_huir.disabled = not activo
	if activo:
		btn_atacar.grab_focus()

func narrar(texto: String):
	lbl_narrativa.show()
	lbl_narrativa.text = texto

func agregar_al_log(mensaje: String):
	print(mensaje)
	texto_log.append_text(mensaje + "\n")

# ===== ACTUALIZACIÓN DE INTERFAZ =====
func actualizar_interfaz_party(party_jugador: Array):
	var paneles = contenedor_party.get_children()
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

			_dibujar_estados_heroe(panel, heroe)
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

# ===== ANIMACIONES DE TURNO =====
func animar_turno_activo(heroe_activo: CharacterStats, party_jugador: Array):
	var paneles = contenedor_party.get_children()
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

func actualizar_linea_turnos(combatientes: Array, turno_actual: int, party_jugador: Array):
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

# ===== EFECTOS VISUALES =====
var fuerza_temblor: float = 0.0

func _process(delta):
	if fuerza_temblor > 0:
		fuerza_temblor = lerpf(fuerza_temblor, 0.0, 5.0 * delta)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * fuerza_temblor

		if fuerza_temblor < 0.5:
			fuerza_temblor = 0.0
			offset = Vector2.ZERO

func aplicar_temblor(porcentaje_dano: float):
	if porcentaje_dano >= 0.75:
		fuerza_temblor = 30.0
	elif porcentaje_dano >= 0.50:
		fuerza_temblor = 18.0
	elif porcentaje_dano >= 0.25:
		fuerza_temblor = 10.0
	else:
		fuerza_temblor = 4.0

func animar_rolleo_hp(lbl_pv, barra_pv, valor_actual: int, valor_final: int, color_hex: String):
	var tween = get_tree().create_tween()

	if barra_pv:
		barra_pv.set_meta("animando", true)

	tween.tween_method(
		func(val):
			if lbl_pv:
				_set_stat_text(lbl_pv, "PV", int(val), color_hex)
			if barra_pv:
				barra_pv.value = val,
		float(valor_actual),
		float(valor_final),
		0.5
	).set_trans(Tween.TRANS_LINEAR)

	if barra_pv:
		tween.tween_callback(func(): barra_pv.remove_meta("animando"))

func mostrar_descripcion_item(descripcion: String):
	lbl_narrativa.show()
	lbl_narrativa.text = descripcion

# ===== INVENTARIO =====
func actualizar_inventario_visual(atacante: CharacterStats, manager: Node):
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
					mostrar_descripcion_item(btn.get_meta("desc_item"))
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
func actualizar_habilidades_visual(atacante: CharacterStats, manager: Node):
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
					mostrar_descripcion_item(btn.get_meta("desc_hab"))
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

# ===== ESTADOS DE HÉROE =====
func _dibujar_estados_heroe(panel_heroe: Panel, heroe: CharacterStats):
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

	if heroe.niveles_stat["ataque"] > 0 and icon_atk_up:
		_crear_icono_estado(contenedor_estados, icon_atk_up)
	elif heroe.niveles_stat["ataque"] < 0 and icon_atk_down:
		_crear_icono_estado(contenedor_estados, icon_atk_down)

	if heroe.niveles_stat["defensa"] > 0 and icon_def_up:
		_crear_icono_estado(contenedor_estados, icon_def_up)
	elif heroe.niveles_stat["defensa"] < 0 and icon_def_down:
		_crear_icono_estado(contenedor_estados, icon_def_down)

	if heroe.niveles_stat["agilidad"] > 0 and icon_agi_up:
		_crear_icono_estado(contenedor_estados, icon_agi_up)
	elif heroe.niveles_stat["agilidad"] < 0 and icon_agi_down:
		_crear_icono_estado(contenedor_estados, icon_agi_down)

	if heroe.niveles_stat["suerte"] > 0 and icon_suerte_up:
		_crear_icono_estado(contenedor_estados, icon_suerte_up)
	elif heroe.niveles_stat["suerte"] < 0 and icon_suerte_down:
		_crear_icono_estado(contenedor_estados, icon_suerte_down)

	if heroe.turnos_provocacion > 0 and icon_provocacion:
		_crear_icono_estado(contenedor_estados, icon_provocacion)
	if heroe.turnos_distraido > 0 and icon_distraido:
		_crear_icono_estado(contenedor_estados, icon_distraido)
	if heroe.esta_defendiendo and icon_defensa:
		_crear_icono_estado(contenedor_estados, icon_defensa)

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

# ===== PANTALLA DE VICTORIA =====
func mostrar_pantalla_victoria(party: Array, exp_total: int, niveles_previos: Dictionary, whenes_total: int = 0, items_ganados: Array = []):
	panel_victoria.show()
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

			# Separador y estadísticas
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

			# Animación de EXP
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

	# Panel de botín
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

		# Slot de whenes
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

		# Slots de items
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

	# Actualización en vivo de la tarjeta
	if labels_estadisticas_heroes.has(heroe_inv_actual) and labels_estadisticas_heroes[heroe_inv_actual].has(clave_stat):
		var lbl_stat_tarjeta = labels_estadisticas_heroes[heroe_inv_actual][clave_stat]
		lbl_stat_tarjeta.text = str(heroe_inv_actual.get(clave_stat))

		# Destello verde para indicar mejora
		var tween = get_tree().create_tween()
		tween.tween_property(lbl_stat_tarjeta, "modulate", Color("55ff55"), 0.1)
		tween.tween_property(lbl_stat_tarjeta, "modulate", Color.WHITE, 0.4)

	actualizar_menu_inversion()
