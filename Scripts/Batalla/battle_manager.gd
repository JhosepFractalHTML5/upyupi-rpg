extends Node

# ===== CONFIGURACIÓN INICIAL =====
var party_jugador: Array[CharacterStats] = []
var oleadas_enemigos: Array = []
@export var ayudante_actual: Ayudante

var enemigos_actuales: Array[CharacterStats] = []
var combatientes: Array[CharacterStats] = []
var turno_actual: int = 0
var indice_oleada: int = 0
var timer_estados: Timer
var indice_rotacion_estado: int = 0
var exp_acumulada: int = 0
var whenes_acumulados: int = 0
var items_dropeados: Array = []

@onready var ui: BattleUI = $CapaGUI

# ===== ESTADO DE SELECCIÓN =====
var seleccionando_objetivo: bool = false
var seleccionando_item: bool = false
var indice_objetivo_actual: int = 0
var accion_pendiente: String = ""
var habilidad_pendiente: Habilidad = null
var item_pendiente: ItemConsumible = null
var sprites_enemigos: Dictionary = {}
var esperando_cierre_batalla: bool = false

# ===== INICIALIZACIÓN =====
func _ready():
	randomize()
	timer_estados = Timer.new()
	timer_estados.wait_time = 1.0
	timer_estados.autostart = true
	timer_estados.timeout.connect(_rotar_estados_enemigos)
	add_child(timer_estados)

	ui.btn_atacar.pressed.connect(_on_btn_atacar_pressed)
	ui.btn_defender.pressed.connect(_on_btn_defender_pressed)
	ui.btn_habilidades.pressed.connect(_on_btn_habilidades_pressed)
	ui.btn_items.pressed.connect(_on_btn_items_pressed)
	ui.btn_huir.pressed.connect(_on_btn_huir_pressed)

	party_jugador = GlobalGame.party_actual
	oleadas_enemigos = GlobalGame.oleadas_combate_actual.duplicate(true)
	iniciar_batalla()

# ===== PROCESAMIENTO DE FRAME =====
func _process(_delta):
	if not seleccionando_objetivo:
		return

	var es_apuntado_aliado = false
	if accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true
	elif accion_pendiente == "ITEM" and item_pendiente and item_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true

	if es_apuntado_aliado:
		for enemigo in sprites_enemigos.keys():
			sprites_enemigos[enemigo].modulate.a = 1.0
		var paneles = ui.contenedor_party.get_children()
		for i in range(paneles.size()):
			if i < party_jugador.size():
				paneles[i].modulate.a = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6) if i == indice_objetivo_actual else 1.0
	else:
		for p in ui.contenedor_party.get_children():
			p.modulate.a = 1.0
		if enemigos_actuales.size() > 0:
			if indice_objetivo_actual >= enemigos_actuales.size():
				indice_objetivo_actual = 0
			var objetivo_actual = enemigos_actuales[indice_objetivo_actual]
			for enemigo in sprites_enemigos.keys():
				if enemigo.pv_actuales > 0:
					sprites_enemigos[enemigo].modulate.a = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6) if enemigo == objetivo_actual else 1.0

# ===== PREPARACIÓN DE BATALLA =====
func iniciar_batalla():
	for heroe in party_jugador:
		# BORRAR: heroe.pt_actuales = randi_range(0, heroe.pt_maximos) <--- ¡CORTA ESTO!
		heroe.cooldowns_actuales.clear()
		heroe.turnos_provocacion = 0
		heroe.turnos_distraido = 0
		heroe.esta_defendiendo = false
		heroe.reiniciar_dano_ronda()
		for stat in heroe.niveles_stat.keys():
			heroe.niveles_stat[stat] = 0
			heroe.turnos_stat[stat] = 0

	ui.agregar_al_log("[SISTEMA] Combate Iniciado.")
	ui.actualizar_interfaz_party(party_jugador)
	cargar_oleada(0)

	ui.agregar_al_log("[SISTEMA] Combate Iniciado.")
	ui.actualizar_interfaz_party(party_jugador)
	cargar_oleada(0)

func cargar_oleada(indice: int):
	indice_oleada = indice
	enemigos_actuales.clear()

	var index_enemigo = 1
	for enemigo_plantilla in oleadas_enemigos[indice]:
		var enemigo_clon = enemigo_plantilla.duplicate(true)
		var nombre_base = enemigo_plantilla.nombre
		if nombre_base == "":
			nombre_base = "Enemigo"
		enemigo_clon.nombre = nombre_base + (" " + str(index_enemigo) if index_enemigo > 1 else "")
		enemigo_clon.pt_actuales = randi_range(0, enemigo_clon.pt_maximos)
		enemigo_clon.cooldowns_actuales.clear()
		enemigos_actuales.append(enemigo_clon)
		index_enemigo += 1

	ui.agregar_al_log("[SISTEMA] Oleada " + str(indice + 1) + " en curso.")
	ui.narrar("¡Comienza la oleada " + str(indice + 1) + "!")
	actualizar_sprites_enemigos()

	await get_tree().create_timer(1.5).timeout
	iniciar_ronda()

func actualizar_sprites_enemigos():
	for hijo in ui.contenedor_enemigos.get_children():
		hijo.queue_free()
	sprites_enemigos.clear()

	for enemigo in enemigos_actuales:
		var rect = TextureRect.new()
		rect.texture = enemigo.textura_sprite
		ui.contenedor_enemigos.add_child(rect)
		sprites_enemigos[enemigo] = rect

		var icono = TextureRect.new()
		icono.name = "IconoEstado"
		icono.custom_minimum_size = Vector2(24, 24)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		icono.position.y = 30
		icono.hide()
		rect.add_child(icono)

# ===== CONTROL DE RONDAS Y TURNOS =====
func iniciar_ronda():
	combatientes.clear()
	turno_actual = 0
	for heroe in party_jugador:
		if heroe.pv_actuales > 0:
			combatientes.append(heroe)
	for enemigo in enemigos_actuales:
		if enemigo.pv_actuales > 0:
			combatientes.append(enemigo)

	combatientes.sort_custom(_ordenar_por_agilidad)
	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)
	iniciar_turno()

func _ordenar_por_agilidad(a: CharacterStats, b: CharacterStats) -> bool:
	var agi_a = a.get_agilidad_real()
	var agi_b = b.get_agilidad_real()
	return agi_a > agi_b

func iniciar_turno():
	var atacante = combatientes[turno_actual]

	# Procesar estados automáticamente
	var estados_expirados = atacante.procesar_turnos_estados()
	var perdio_provocacion = "PROVOCACION" in estados_expirados
	var perdio_distraccion = "DISTRACCION" in estados_expirados

	if party_jugador.has(atacante):
		for hab in atacante.cooldowns_actuales.keys():
			if atacante.cooldowns_actuales[hab] > 0:
				atacante.cooldowns_actuales[hab] -= 1

	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)

	if party_jugador.has(atacante):
		ui.animar_turno_activo(atacante, party_jugador)
		ui.actualizar_inventario_visual(atacante, self)
		ui.actualizar_habilidades_visual(atacante, self)
	else:
		ui.animar_turno_activo(null, party_jugador)
		ui.grid_items.hide()
		ui.grid_habilidades.hide()

	# Narrativas de estados expirados
	if perdio_provocacion:
		ui.narrar(atacante.nombre + " ya no quiere ser el centro de los golpes.")
		ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Escudo Humano")
		await get_tree().create_timer(1.5).timeout

	if perdio_distraccion:
		ui.narrar(atacante.nombre + " vuelve a concentrarse.")
		ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Distraído")
		await get_tree().create_timer(1.5).timeout

	if enemigos_actuales.has(atacante):
		ui.set_menu_activo(false)
		ui.narrar("Turno de " + atacante.nombre + ".")
		await atacante.ejecutar_ia(self, party_jugador)
	else:
		ui.retrato_activo.texture = atacante.retrato_base
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)

# ===== ACCIONES DEL JUGADOR =====
func _on_btn_atacar_pressed():
	ui.set_menu_activo(false)
	accion_pendiente = "ATACAR"
	iniciar_seleccion_objetivo()

func _on_btn_defender_pressed():
	ui.set_menu_activo(false)
	var atacante = combatientes[turno_actual]
	atacante.activar_defensa()

	var recuperacion = int((atacante.ph_maximos * 0.05) + 5)
	atacante.ph_actuales = min(atacante.ph_actuales + recuperacion, atacante.ph_maximos)

	# Aplicar multiplicador de Recuperación de PT
	var pt_ganados = int(15 * atacante.recuperacion_pt)
	atacante.pt_actuales = min(atacante.pt_actuales + pt_ganados, atacante.pt_maximos)

	ui.agregar_al_log("[ACCIÓN] " + atacante.nombre + " usó Defensa (+" + str(pt_ganados) + " PT).")
	ui.narrar("¡" + atacante.nombre + " adopta una postura defensiva!")
	ui.actualizar_interfaz_party(party_jugador)
	await get_tree().create_timer(1.2).timeout
	pasar_turno()

func _on_btn_huir_pressed():
	ui.set_menu_activo(false)
	ui.narrar("¡Intentas escapar de la batalla!")

# ===== SISTEMA DE ITEMS =====
func _on_btn_items_pressed():
	ui.set_menu_activo(false)
	var atacante = combatientes[turno_actual]
	var primer_boton = null

	for btn in ui.grid_items.get_children():
		if btn.get_meta("es_valido"):
			btn.disabled = false
			btn.focus_mode = Control.FOCUS_ALL
			if primer_boton == null:
				primer_boton = btn

	if primer_boton != null:
		accion_pendiente = "ITEM_MENU"
		primer_boton.grab_focus()
		ui.mostrar_descripcion_item(primer_boton.get_meta("desc_item"))
	else:
		ui.narrar("¡El inventario de " + atacante.nombre + " está vacío!")
		await get_tree().create_timer(1.2).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)

func bloquear_grid_items():
	for btn in ui.grid_items.get_children():
		btn.disabled = true

func _seleccionar_item(item: ItemConsumible):
	bloquear_grid_items()
	accion_pendiente = "ITEM"
	item_pendiente = item

	if item.objetivo == "usuario":
		_ejecutar_item(combatientes[turno_actual], combatientes[turno_actual])
	else:
		iniciar_seleccion_objetivo()

func _ejecutar_item(atacante: CharacterStats, defensor: CharacterStats):
	ui.narrar("¡" + atacante.nombre + " usó " + item_pendiente.nombre + " en " + defensor.nombre + "!")
	await get_tree().create_timer(1.0).timeout

	# Farmacología: eficiencia en curaciones
	var bono_farmacologia = defensor.farmacologia

	if item_pendiente.tipo_efecto == "CURAR_PV":
		var sanacion = int(item_pendiente.poder * bono_farmacologia)
		defensor.pv_actuales = min(defensor.pv_actuales + sanacion, defensor.pv_maximos)
		ui.agregar_al_log("[ITEM] " + defensor.nombre + " recuperó " + str(sanacion) + " PV.")
		ui.narrar("¡" + defensor.nombre + " recuperó salud!")
		mostrar_numero_flotante(defensor, sanacion, "cura")
	elif item_pendiente.tipo_efecto == "CURAR_PH":
		var sanacion = int(item_pendiente.poder * bono_farmacologia)
		defensor.ph_actuales = min(defensor.ph_actuales + sanacion, defensor.ph_maximos)
		ui.agregar_al_log("[ITEM] " + defensor.nombre + " recuperó " + str(sanacion) + " PH.")
		ui.narrar("¡" + defensor.nombre + " recuperó concentración!")

	atacante.inventario.erase(item_pendiente)
	item_pendiente = null
	ui.actualizar_inventario_visual(atacante, self)
	verificar_estado_batalla(defensor, true)

# ===== SISTEMA DE HABILIDADES =====
func _on_btn_habilidades_pressed():
	ui.set_menu_activo(false)
	var atacante = combatientes[turno_actual]
	var primer_boton = null

	for btn in ui.grid_habilidades.get_children():
		if btn.has_meta("es_valida") and btn.get_meta("es_valida"):
			btn.disabled = false
			btn.focus_mode = Control.FOCUS_ALL
			if primer_boton == null:
				primer_boton = btn

	if primer_boton != null:
		accion_pendiente = "HABILIDAD_MENU"
		primer_boton.grab_focus()
		ui.mostrar_descripcion_item(primer_boton.get_meta("desc_hab"))
	else:
		ui.narrar("No hay habilidades desbloqueadas.")
		await get_tree().create_timer(1.0).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)

func bloquear_grid_habilidades():
	for btn in ui.grid_habilidades.get_children():
		btn.disabled = true

func _seleccionar_habilidad(hab: Habilidad):
	var atacante = combatientes[turno_actual]
	var turnos_cd = atacante.cooldowns_actuales[hab] if atacante.cooldowns_actuales.has(hab) else 0

	if turnos_cd > 0:
		ui.narrar("¡Habilidad en recarga!")
		await get_tree().create_timer(1.2).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)
		bloquear_grid_habilidades()
		return

	if atacante.turnos_distraido > 0 and hab.es_ataque_fuerte:
		ui.narrar("¡" + atacante.nombre + " está muy distraído para concentrarse!")
		await get_tree().create_timer(1.5).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)
		bloquear_grid_habilidades()
		return

	if atacante.ph_actuales >= hab.costo_ph and atacante.pt_actuales >= hab.costo_pt:
		bloquear_grid_habilidades()
		habilidad_pendiente = hab
		accion_pendiente = "HABILIDAD"

		var objs_automaticos = ["usuario", "aleatorio_enemigos", "aleatorio_aliados", "todos_enemigos", "todos_aliados"]
		if hab.objetivo in objs_automaticos:
			_ejecutar_habilidad_preparada(atacante, null)
		else:
			iniciar_seleccion_objetivo()
	else:
		ui.narrar("¡Recursos insuficientes!")
		await get_tree().create_timer(1.0).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)
		bloquear_grid_habilidades()

func _ejecutar_habilidad_preparada(atacante: CharacterStats, defensor: CharacterStats):
	atacante.gastar_ph(habilidad_pendiente.costo_ph)
	atacante.pt_actuales -= habilidad_pendiente.costo_pt
	if habilidad_pendiente.cooldown > 0:
		atacante.cooldowns_actuales[habilidad_pendiente] = habilidad_pendiente.cooldown
	ui.actualizar_interfaz_party(party_jugador)
	await habilidad_pendiente.ejecutar(atacante, defensor, self)
	ui.actualizar_interfaz_party(party_jugador)

# ===== SELECCIÓN DE OBJETIVOS =====
func iniciar_seleccion_objetivo():
	seleccionando_objetivo = true
	indice_objetivo_actual = 0
	_actualizar_texto_seleccion()

func _actualizar_texto_seleccion():
	var es_apuntado_aliado = false
	if accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true
	elif accion_pendiente == "ITEM" and item_pendiente and item_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true

	var nombre_obj = ""
	if es_apuntado_aliado:
		if indice_objetivo_actual < party_jugador.size():
			nombre_obj = party_jugador[indice_objetivo_actual].nombre
	else:
		if indice_objetivo_actual < enemigos_actuales.size():
			nombre_obj = enemigos_actuales[indice_objetivo_actual].nombre

	ui.narrar("Selecciona objetivo:\n> " + nombre_obj + " <")

func _unhandled_input(event):
	# Salir de la batalla
	if esperando_cierre_batalla and event.is_action_pressed("ui_accept"):
		esperando_cierre_batalla = false
		ui.narrar("Volviendo al mapa...")

		# Regreso al mapa anterior
		if GlobalGame.mapa_anterior_ruta != "":
			GlobalGame.volver_de_batalla = true
			get_tree().change_scene_to_file(GlobalGame.mapa_anterior_ruta)
		else:
			ui.narrar("Error: No hay un mapa guardado en la memoria.")
		return

	if accion_pendiente == "HABILIDAD_MENU" and event.is_action_pressed("ui_cancel"):
		accion_pendiente = ""
		bloquear_grid_habilidades()
		ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
		ui.set_menu_activo(true)
		get_viewport().set_input_as_handled()
		return

	if accion_pendiente == "ITEM_MENU" and event.is_action_pressed("ui_cancel"):
		accion_pendiente = ""
		bloquear_grid_items()
		ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
		ui.set_menu_activo(true)
		get_viewport().set_input_as_handled()
		return

	if not seleccionando_objetivo:
		return

	var max_objetivos = enemigos_actuales.size()
	if (accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado") or \
	   (accion_pendiente == "ITEM" and item_pendiente and item_pendiente.objetivo == "aliado"):
		max_objetivos = party_jugador.size()

	if event.is_action_pressed("ui_right"):
		indice_objetivo_actual = (indice_objetivo_actual + 1) % max_objetivos
		_actualizar_texto_seleccion()
	elif event.is_action_pressed("ui_left"):
		indice_objetivo_actual = (indice_objetivo_actual - 1 + max_objetivos) % max_objetivos
		_actualizar_texto_seleccion()
	elif event.is_action_pressed("ui_accept"):
		confirmar_seleccion()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancelar_seleccion()
		get_viewport().set_input_as_handled()

func cancelar_seleccion():
	seleccionando_objetivo = false
	for enemigo in sprites_enemigos.keys():
		if enemigo.pv_actuales > 0:
			sprites_enemigos[enemigo].modulate.a = 1.0
	for p in ui.contenedor_party.get_children():
		p.modulate.a = 1.0
	ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
	ui.set_menu_activo(true)

func confirmar_seleccion():
	seleccionando_objetivo = false
	var atacante = combatientes[turno_actual]
	var defensor: CharacterStats = null

	var es_apuntado_aliado = false
	if accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true
	elif accion_pendiente == "ITEM" and item_pendiente and item_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true

	if es_apuntado_aliado:
		if indice_objetivo_actual >= party_jugador.size():
			indice_objetivo_actual = 0
		defensor = party_jugador[indice_objetivo_actual]
	else:
		if indice_objetivo_actual >= enemigos_actuales.size():
			indice_objetivo_actual = 0
		defensor = enemigos_actuales[indice_objetivo_actual]

	for enemigo in sprites_enemigos.keys():
		if enemigo.pv_actuales > 0:
			sprites_enemigos[enemigo].modulate.a = 1.0
	for p in ui.contenedor_party.get_children():
		p.modulate.a = 1.0

	if accion_pendiente == "ATACAR":
		ui.narrar("¡" + atacante.nombre + " ataca a " + defensor.nombre + "!")
		atacante.pt_actuales = min(atacante.pt_actuales + int(10 * atacante.recuperacion_pt), atacante.pt_maximos)
		await get_tree().create_timer(0.8).timeout
		await defensor.recibir_ataque(atacante, self)
	elif accion_pendiente == "HABILIDAD":
		_ejecutar_habilidad_preparada(atacante, defensor)
	elif accion_pendiente == "ITEM":
		_ejecutar_item(atacante, defensor)

# ===== VERIFICACIÓN DE ESTADO DE BATALLA =====
func verificar_estado_batalla(defensor, pasar_el_turno: bool = true) -> bool:
	ui.actualizar_interfaz_party(party_jugador)
	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)

	if defensor.pv_actuales <= 0:
		ui.narrar("¡" + defensor.nombre + " ha caído!")
		ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)
		await get_tree().create_timer(1.0).timeout

		if enemigos_actuales.has(defensor):
			if defensor.get("drop_experiencia"):
				exp_acumulada += defensor.drop_experiencia
			var sprite_muerto = sprites_enemigos[defensor]
			var tween = get_tree().create_tween()
			tween.tween_property(sprite_muerto, "modulate:a", 0.0, 0.5)
			enemigos_actuales.erase(defensor)

			# Recolectar whenes e items
			if defensor.get("drop_whenes"):
				whenes_acumulados += defensor.drop_whenes

			if defensor.get("item_dropeable") and defensor.item_dropeable != null:
				if randf() * 100.0 <= defensor.chance_drop:
					items_dropeados.append(defensor.item_dropeable)

			if enemigos_actuales.is_empty():
				_procesar_fin_oleada()
				return false
		elif party_jugador.has(defensor):
			var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
			if heroes_vivos.is_empty():
				ui.narrar("El grupo ha sido aniquilado...")
				return false

	if pasar_el_turno:
		pasar_turno()
	return true

func _procesar_fin_oleada():
	indice_oleada += 1
	if indice_oleada < oleadas_enemigos.size():
		ui.narrar("¡Más enemigos se acercan!")
		await get_tree().create_timer(1.0).timeout
		cargar_oleada(indice_oleada)
	else:
		# Final de combate
		if timer_estados:
			timer_estados.stop()

		ui.narrar("¡Has ganado la batalla!")
		await get_tree().create_timer(1.5).timeout

		# Guardar niveles previos
		var niveles_previos = {}
		for heroe in party_jugador:
			niveles_previos[heroe] = heroe.nivel

		# Aplicar experiencia
		for heroe in party_jugador:
			if heroe.pv_actuales > 0:
				heroe.ganar_experiencia(exp_acumulada)

		# Mostrar pantalla de victoria con botín
		ui.mostrar_pantalla_victoria(party_jugador, exp_acumulada, niveles_previos, whenes_acumulados, items_dropeados)
		ui.narrar("¡El grupo obtiene experiencia y botín!")

		# Guardar botín en inventario global
		GlobalGame.agregar_whenes(whenes_acumulados)
		for item in items_dropeados:
			GlobalGame.inventario_equipamiento.append(item)

		whenes_acumulados = 0
		items_dropeados.clear()

		# Sistema de inversión de puntos
		for heroe in party_jugador:
			if heroe.pv_actuales > 0 and heroe.puntos_estadisticas > 0:
				ui.narrar("¡" + heroe.nombre + " tiene puntos para invertir!")
				ui.abrir_menu_inversion(heroe)
				await ui.inversion_completada

		ui.narrar("Presiona 'Aceptar' para continuar...")
		esperando_cierre_batalla = true

func pasar_turno():
	turno_actual += 1
	if turno_actual >= combatientes.size():
		_procesar_fin_de_ronda()
	else:
		if combatientes[turno_actual].pv_actuales <= 0:
			pasar_turno()
			return
		await get_tree().create_timer(0.8).timeout
		iniciar_turno()

func _procesar_fin_de_ronda():
	var alguien_desperto = false

	for c in combatientes:
		if c.pv_actuales > 0 and c.turnos_distraido > 0:
			if c.dano_recibido_esta_ronda >= (c.pv_maximos * 0.25):
				c.turnos_distraido = 0
				ui.actualizar_interfaz_party(party_jugador)
				ui.agregar_al_log("[ESTADO] " + c.nombre + " -/> Distraído (Golpe Masivo)")
				ui.narrar("¡El dolor hace que " + c.nombre + " vuelva a concentrarse!")
				alguien_desperto = true
				await get_tree().create_timer(1.5).timeout
		c.reiniciar_dano_ronda()

	# Lógica del ayudante
	if not alguien_desperto:
		if ayudante_actual != null:
			await ayudante_actual.ejecutar_asistencia(self)
		else:
			ui.narrar("La batalla continúa en silencio...")
			await get_tree().create_timer(1.0).timeout

	iniciar_ronda()

# ===== UTILIDADES VISUALES =====
func mostrar_numero_flotante(objetivo: CharacterStats, cantidad: int, tipo: String):
	var color = Color.RED
	if tipo == "atipico":
		color = Color.PURPLE
	elif tipo == "cura":
		color = Color.GREEN

	var nodo_objetivo = null
	if party_jugador.has(objetivo):
		var index = party_jugador.find(objetivo)
		nodo_objetivo = ui.contenedor_party.get_child(index)
	elif sprites_enemigos.has(objetivo):
		nodo_objetivo = sprites_enemigos[objetivo]

	if not nodo_objetivo:
		return

	var lbl = Label.new()
	lbl.text = str(cantidad)
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.z_index = 50

	var pos_global = nodo_objetivo.global_position
	lbl.position = pos_global + (nodo_objetivo.size / 2.0) - Vector2(10, 20)
	ui.add_child(lbl)

	var tween = get_tree().create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 50, 1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(lbl.queue_free)

func animar_parpadeo_enemigo(enemigo: CharacterStats):
	if sprites_enemigos.has(enemigo):
		var sprite = sprites_enemigos[enemigo]
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)

# ===== SISTEMA DE ESTADOS VISUALES =====
func _rotar_estados_enemigos():
	indice_rotacion_estado += 1
	for enemigo in enemigos_actuales:
		if not sprites_enemigos.has(enemigo):
			continue
		var rect = sprites_enemigos[enemigo]
		var nodo_icono = rect.get_node_or_null("IconoEstado")
		if not nodo_icono:
			continue

		var activos = []
		if enemigo.niveles_stat["ataque"] > 0 and ui.icon_atk_up:
			activos.append(ui.icon_atk_up)
		elif enemigo.niveles_stat["ataque"] < 0 and ui.icon_atk_down:
			activos.append(ui.icon_atk_down)
		if enemigo.niveles_stat["defensa"] > 0 and ui.icon_def_up:
			activos.append(ui.icon_def_up)
		elif enemigo.niveles_stat["defensa"] < 0 and ui.icon_def_down:
			activos.append(ui.icon_def_down)
		if enemigo.niveles_stat["agilidad"] > 0 and ui.icon_agi_up:
			activos.append(ui.icon_agi_up)
		elif enemigo.niveles_stat["agilidad"] < 0 and ui.icon_agi_down:
			activos.append(ui.icon_agi_down)
		if enemigo.niveles_stat["suerte"] > 0 and ui.icon_suerte_up:
			activos.append(ui.icon_suerte_up)
		elif enemigo.niveles_stat["suerte"] < 0 and ui.icon_suerte_down:
			activos.append(ui.icon_suerte_down)

		if enemigo.turnos_provocacion > 0 and ui.icon_provocacion:
			activos.append(ui.icon_provocacion)
		if enemigo.turnos_distraido > 0 and ui.icon_distraido:
			activos.append(ui.icon_distraido)
		if enemigo.esta_defendiendo and ui.icon_defensa:
			activos.append(ui.icon_defensa)

		if activos.is_empty():
			nodo_icono.hide()
		else:
			nodo_icono.show()
			nodo_icono.texture = activos[indice_rotacion_estado % activos.size()]

# ===== SELECCIÓN DE OBJETIVO POR AGGRO =====
func obtener_objetivo_por_aggro(objetivos_posibles: Array) -> CharacterStats:
	var total_aggro = 0.0
	for obj in objetivos_posibles:
		total_aggro += obj.tasa_objetivo

	var rand_val = randf() * total_aggro
	var acumulado = 0.0

	for obj in objetivos_posibles:
		acumulado += obj.tasa_objetivo
		if rand_val <= acumulado:
			return obj
	return objetivos_posibles[0]
