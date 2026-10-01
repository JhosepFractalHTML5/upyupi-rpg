extends Node

# ===== CONFIGURACIÓN INICIAL =====
var party_jugador: Array[CharacterStats] = []
var oleadas_enemigos: Array = []
@export var ayudante_actual: Ayudante

var enemigos_actuales: Array[CharacterStats] = []
var combatientes: Array[CharacterStats] = []
var turno_actual: int = 0
var indice_oleada: int = 0
var exp_acumulada: int = 0
var whenes_acumulados: int = 0
var items_dropeados: Array = []

@onready var gestor_reparto = $GestorReparto
@onready var selector_objetivos = $SelectorObjetivos
@onready var ui: BattleUI = $CapaGUI

# ===== ESTADO DE SELECCIÓN =====
var seleccionando_item: bool = false
var accion_pendiente: String = ""
var habilidad_pendiente: Habilidad = null
var item_pendiente: Item = null
var sprites_enemigos: Dictionary = {}
var esperando_cierre_batalla: bool = false
var bloquear_todo_input: bool = false # <--- SOLUCIÓN DE MISTRAL: El gran sello

# ===== INICIALIZACIÓN =====
func _ready():
	randomize()

	ui.btn_atacar.pressed.connect(_on_btn_atacar_pressed)
	ui.btn_defender.pressed.connect(_on_btn_defender_pressed)
	ui.btn_habilidades.pressed.connect(_on_btn_habilidades_pressed)
	ui.btn_items.pressed.connect(_on_btn_items_pressed)
	ui.btn_huir.pressed.connect(_on_btn_huir_pressed)
	
	party_jugador = GlobalGame.party_actual
	oleadas_enemigos = GlobalGame.oleadas_combate_actual.duplicate(true)
	iniciar_batalla()
	selector_objetivos.objetivo_confirmado.connect(_on_objetivo_confirmado)
	selector_objetivos.seleccion_cancelada.connect(cancelar_seleccion)

# ===== BLOQUEO DE BOTONES =====
func _bloquear_botones_accion():
	ui.btn_atacar.disabled = true
	ui.btn_defender.disabled = true
	ui.btn_habilidades.disabled = true
	ui.btn_items.disabled = true
	ui.btn_huir.disabled = true

func _desbloquear_botones_accion():
	ui.btn_atacar.disabled = false
	ui.btn_defender.disabled = false
	ui.btn_habilidades.disabled = false
	ui.btn_items.disabled = false
	ui.btn_huir.disabled = false

# ===== PREPARACIÓN DE BATALLA =====
func iniciar_batalla():
	for heroe in party_jugador:
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
	ui.iniciar_sistema_estados(enemigos_actuales, sprites_enemigos)
	
# ===== CONTROL DE RONDAS Y TURNOS =====
func iniciar_ronda():
	combatientes.clear()
	turno_actual = 0
	for heroe in party_jugador:
		if heroe.pv_actuales > 0:
			combatientes.append(heroe)
	for enemigo in enemigos_actuales:
		if is_instance_valid(enemigo) and enemigo.pv_actuales > 0:
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
	
	if not is_instance_valid(atacante):
		pasar_turno()
		return

	var estados_expirados = atacante.procesar_turnos_estados()
	var perdio_provocacion = "PROVOCACION" in estados_expirados
	var perdio_distraccion = "DISTRACCION" in estados_expirados
	var perdio_voluntad = "VOLUNTAD_HUMANA" in estados_expirados
	var perdio_enamoramiento = "ENAMORADO" in estados_expirados

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

	if perdio_provocacion and not perdio_voluntad: 
		ui.narrar(atacante.nombre + " ya no quiere ser el centro de los golpes.")
		ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Provocación") 
		await get_tree().create_timer(1.5).timeout

	if perdio_distraccion:
		ui.narrar(atacante.nombre + " vuelve a concentrarse.")
		ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Distraído")
		await get_tree().create_timer(1.5).timeout
		
	if perdio_enamoramiento:
		ui.narrar(atacante.nombre + " parpadea, confundido... ¡Se acabó el encanto!")
		ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Enamorado")
		await get_tree().create_timer(1.5).timeout

	if perdio_voluntad:
		# Usamos get() por seguridad en caso de que sea una IA
		if atacante.get("revivido_por_voluntad"):
			ui.narrar("El trance de " + atacante.nombre + " termina... ¡El dolor drenó su vitalidad!")
			atacante.pv_actuales = 0
			atacante.limpiar_estados()
			if "revivido_por_voluntad" in atacante:
				atacante.revivido_por_voluntad = false
			ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Voluntad (Muerte)")
			ui.actualizar_interfaz_party(party_jugador) 
			await get_tree().create_timer(2.0).timeout
			
			# Llamamos a verificar_estado_batalla SIN pasar turno automático, 
			# para que procese el "Game Over" si Jhosep era el último vivo.
			var batalla_continua = await verificar_estado_batalla(atacante, false)
			
			# --- SOLUCIÓN APLICADA ---
			if batalla_continua:
				# Si la batalla sigue, pasamos el turno del personaje muerto.
				pasar_turno() 
			
			# ¡SIEMPRE hacemos return! Porque si está muerto, o la batalla acabó,
			# de ninguna forma debe continuar leyendo el código hacia abajo.
			return 
		else:
			ui.narrar("La voluntad de " + atacante.nombre + " se asienta, endureciendo su piel.")
			ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Voluntad Humana (DEF+)")
			ui.actualizar_interfaz_party(party_jugador) 
			await get_tree().create_timer(2.0).timeout

	# 6. Acción del turno (Enemigo o Jugador)
	if enemigos_actuales.has(atacante):
		bloquear_todo_input = true # ¡Sellan todo input en turno enemigo!
		ui.set_menu_activo(false)
		ui.narrar("Turno de " + atacante.nombre + ".")
		await atacante.ejecutar_ia(self, party_jugador)
	else:
		bloquear_todo_input = false # Desbloqueamos para el jugador
		ui.retrato_activo.texture = atacante.retrato_base
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		_desbloquear_botones_accion() 
		ui.set_menu_activo(true)

# ===== ACCIONES DEL JUGADOR =====
func _on_btn_atacar_pressed():
	if ui.btn_atacar.disabled or bloquear_todo_input: return 
	_bloquear_botones_accion()
	ui.set_menu_activo(false)
	accion_pendiente = "ATACAR"
	iniciar_seleccion_objetivo()

func _on_btn_defender_pressed():
	if ui.btn_defender.disabled or bloquear_todo_input: return
	bloquear_todo_input = true # Entramos a animación
	_bloquear_botones_accion()
	ui.set_menu_activo(false)
	
	var atacante = combatientes[turno_actual]
	atacante.activar_defensa()

	var recuperacion = int((atacante.ph_maximos * 0.05) + 5)
	atacante.ph_actuales = min(atacante.ph_actuales + recuperacion, atacante.ph_maximos)

	var pt_ganados = int(15 * atacante.recuperacion_pt)
	atacante.pt_actuales = min(atacante.pt_actuales + pt_ganados, atacante.pt_maximos)

	ui.agregar_al_log("[ACCIÓN] " + atacante.nombre + " usó Defensa (+" + str(pt_ganados) + " PT).")
	ui.narrar("¡" + atacante.nombre + " adopta una postura defensiva!")
	ui.actualizar_interfaz_party(party_jugador)
	await get_tree().create_timer(1.2).timeout
	pasar_turno()

func _on_btn_huir_pressed():
	if ui.btn_huir.disabled or bloquear_todo_input: return
	bloquear_todo_input = true # Entramos a animación
	_bloquear_botones_accion()
	ui.set_menu_activo(false)
	ui.narrar("¡Intentas escapar de la batalla!")
	await get_tree().create_timer(1.5).timeout
	pasar_turno()

# ===== SISTEMA DE ITEMS =====
func _on_btn_items_pressed():
	if ui.btn_items.disabled or bloquear_todo_input: return
	_bloquear_botones_accion()
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
		_desbloquear_botones_accion()
		ui.set_menu_activo(true)

func bloquear_grid_items():
	for btn in ui.grid_items.get_children():
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE

func _seleccionar_item(item: Item):
	bloquear_grid_items()
	get_viewport().gui_release_focus()
	accion_pendiente = "ITEM"
	item_pendiente = item

	if item.objetivo == "usuario":
		bloquear_todo_input = true
		_ejecutar_item(combatientes[turno_actual], combatientes[turno_actual])
	else:
		iniciar_seleccion_objetivo()

func _ejecutar_item(atacante: CharacterStats, defensor: CharacterStats):
	ui.narrar("¡" + atacante.nombre + " usó " + item_pendiente.nombre + " en " + defensor.nombre + "!")
	await get_tree().create_timer(1.0).timeout

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
	await verificar_estado_batalla(defensor, true)

# ===== SISTEMA DE HABILIDADES =====
func _on_btn_habilidades_pressed():
	if ui.btn_habilidades.disabled or bloquear_todo_input: return
	_bloquear_botones_accion()
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
		_desbloquear_botones_accion()
		ui.set_menu_activo(true)

func bloquear_grid_habilidades():
	for btn in ui.grid_habilidades.get_children():
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE

func _seleccionar_habilidad(hab: Habilidad):
	var atacante = combatientes[turno_actual]
	var turnos_cd = atacante.cooldowns_actuales[hab] if atacante.cooldowns_actuales.has(hab) else 0

	if turnos_cd > 0:
		ui.narrar("¡Habilidad en recarga!")
		await get_tree().create_timer(1.2).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		_desbloquear_botones_accion()
		ui.set_menu_activo(true)
		bloquear_grid_habilidades()
		return

	if atacante.turnos_distraido > 0 and hab.es_ataque_fuerte:
		ui.narrar("¡" + atacante.nombre + " está muy distraído para concentrarse!")
		await get_tree().create_timer(1.5).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		_desbloquear_botones_accion()
		ui.set_menu_activo(true)
		bloquear_grid_habilidades()
		return

	if atacante.ph_actuales >= hab.costo_ph and atacante.pt_actuales >= hab.costo_pt:
		bloquear_grid_habilidades()
		get_viewport().gui_release_focus()
		habilidad_pendiente = hab
		accion_pendiente = "HABILIDAD"

		var objs_automaticos = ["usuario", "aleatorio_enemigos", "aleatorio_aliados", "todos_enemigos", "todos_aliados"]
		if hab.objetivo in objs_automaticos:
			bloquear_todo_input = true
			_ejecutar_habilidad_preparada(atacante, null)
		else:
			iniciar_seleccion_objetivo()
	else:
		ui.narrar("¡Recursos insuficientes!")
		await get_tree().create_timer(1.0).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		_desbloquear_botones_accion()
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

func _unhandled_input(event):
	if bloquear_todo_input:
		return

	if esperando_cierre_batalla and event.is_action_pressed("ui_accept"):
		esperando_cierre_batalla = false
		ui.narrar("Volviendo al mapa...")
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
		_desbloquear_botones_accion()
		ui.set_menu_activo(true)
		get_viewport().set_input_as_handled()
		return

	if accion_pendiente == "ITEM_MENU" and event.is_action_pressed("ui_cancel"):
		accion_pendiente = ""
		bloquear_grid_items()
		ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
		_desbloquear_botones_accion()
		ui.set_menu_activo(true)
		get_viewport().set_input_as_handled()
		return

# ===== SELECCIÓN DE OBJETIVOS =====
func iniciar_seleccion_objetivo():
	var es_apuntado_aliado = false
	if accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true
	elif accion_pendiente == "ITEM" and item_pendiente and item_pendiente.objetivo == "aliado":
		es_apuntado_aliado = true

	var blancos_posibles = party_jugador if es_apuntado_aliado else enemigos_actuales
	selector_objetivos.iniciar(blancos_posibles, self, ui)

func cancelar_seleccion():
	# El selector ya limpió la transparencia, solo restauramos la UI
	ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
	_desbloquear_botones_accion() 
	ui.set_menu_activo(true)

func _on_objetivo_confirmado(defensor: CharacterStats):
	bloquear_todo_input = true # Entramos a animación
	var atacante = combatientes[turno_actual]

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
	if not is_instance_valid(defensor): return false

	ui.actualizar_interfaz_party(party_jugador)
	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)

	if defensor.pv_actuales <= 0:
		# ¡INYECCIÓN MÉDICA! Interceptamos la muerte si tiene Voluntad Humana activa
		# Solución definitiva: obtenemos valores primero, luego verificamos
		var turnos_vol_humana = defensor.get("turnos_voluntad_humana")
		var has_voluntad_humana = turnos_vol_humana != null and turnos_vol_humana > 0
		

		if has_voluntad_humana:
			defensor.pv_actuales = 1
			if "revivido_por_voluntad" in defensor:
				defensor.revivido_por_voluntad = true
			ui.narrar("¡" + defensor.nombre + " se niega a caer por pura voluntad!")
			ui.agregar_al_log("[ESTADO] " + defensor.nombre + " burló a la muerte.")
			ui.actualizar_interfaz_party(party_jugador)

			if pasar_el_turno:
				pasar_turno()
			return true

		# Si no tiene voluntad o ya se agotó, muere normalmente
		defensor.limpiar_estados()
		ui.narrar("¡" + defensor.nombre + " ha caído!")
		ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)
		await get_tree().create_timer(1.0).timeout

		if enemigos_actuales.has(defensor):
			if defensor.get("drop_experiencia"):
				exp_acumulada += defensor.drop_experiencia
			var sprite_muerto = sprites_enemigos[defensor]

			if is_instance_valid(sprite_muerto):
				var tween = get_tree().create_tween()
				tween.tween_property(sprite_muerto, "modulate:a", 0.0, 0.5)
				await tween.finished

			enemigos_actuales.erase(defensor)

			if defensor.get("drop_whenes"):
				whenes_acumulados += defensor.drop_whenes

			if defensor.get("item_dropeable") and defensor.item_dropeable != null:
				if randf() * 100.0 <= defensor.chance_drop:
					items_dropeados.append(defensor.item_dropeable)

			if enemigos_actuales.is_empty():
				await _procesar_fin_oleada()
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
		ui.detener_sistema_estados() # <--- ¡MÁGIA MODULAR!
		ui.narrar("¡Has ganado la batalla!")
		await get_tree().create_timer(1.5).timeout

		var niveles_previos = {}
		for heroe in party_jugador:
			niveles_previos[heroe] = heroe.nivel

		for heroe in party_jugador:
			if heroe.pv_actuales > 0:
				heroe.ganar_experiencia(exp_acumulada)

		ui.mostrar_pantalla_victoria(party_jugador, exp_acumulada, niveles_previos, whenes_acumulados, items_dropeados)
		ui.narrar("¡El grupo obtiene experiencia y botín!")

		GlobalGame.agregar_whenes(whenes_acumulados)
		
		# --- NUEVO REPARTO MODULAR ---
		var consumibles_a_repartir: Array[Item] = []
		for item in items_dropeados:
			if item.categoria == "Consumible":
				consumibles_a_repartir.append(item)
			else:
				GlobalGame.inventario_equipamiento.append(item) 

		whenes_acumulados = 0
		items_dropeados.clear()

		for heroe in party_jugador:
			if heroe.pv_actuales > 0 and heroe.puntos_estadisticas > 0:
				ui.narrar("¡" + heroe.nombre + " tiene puntos para invertir!")
				ui.abrir_menu_inversion(heroe)
				await ui.inversion_completada

		if consumibles_a_repartir.size() > 0:
			gestor_reparto.iniciar_reparto(consumibles_a_repartir, party_jugador, ui)
			await gestor_reparto.reparto_finalizado # ¡Esperamos elegantemente a que termine!
		else:
			ui.narrar("Presiona 'Aceptar' para continuar...")
			
		bloquear_todo_input = false 
		esperando_cierre_batalla = true

func pasar_turno():
	turno_actual += 1
	if turno_actual >= combatientes.size():
		_procesar_fin_de_ronda()
	else:
		if is_instance_valid(combatientes[turno_actual]) and combatientes[turno_actual].pv_actuales <= 0:
			pasar_turno()
			return
		await get_tree().create_timer(1.2).timeout # Modificación de Mistral (Aumentado a 1.2)
		bloquear_todo_input = false # SOLUCIÓN: Desbloqueamos TODO para el nuevo turno
		iniciar_turno()

func _procesar_fin_de_ronda():
	var alguien_desperto = false

	for c in combatientes:
		if is_instance_valid(c) and c.pv_actuales > 0 and c.turnos_distraido > 0:
			if c.dano_recibido_esta_ronda >= (c.pv_maximos * 0.25):
				c.turnos_distraido = 0
				ui.actualizar_interfaz_party(party_jugador)
				ui.agregar_al_log("[ESTADO] " + c.nombre + " -/> Distraído (Golpe Masivo)")
				ui.narrar("¡El dolor hace que " + c.nombre + " vuelva a concentrarse!")
				alguien_desperto = true
				await get_tree().create_timer(1.5).timeout
		if is_instance_valid(c):
			c.reiniciar_dano_ronda()

	if not alguien_desperto:
		if ayudante_actual != null:
			await ayudante_actual.ejecutar_asistencia(self)
		else:
			ui.narrar("La batalla continúa en silencio...")
			await get_tree().create_timer(1.0).timeout

	iniciar_ronda()

# ===== PUENTES VISUALES (Delegados a la UI) =====

# Un traductor interno: Pide Stats y devuelve Nodos Visuales
func _obtener_nodo_visual(objetivo: CharacterStats) -> Control:
	if party_jugador.has(objetivo) and is_instance_valid(objetivo):
		var index = party_jugador.find(objetivo)
		if index >= 0 and index < ui.contenedor_party.get_child_count():
			return ui.contenedor_party.get_child(index)
	elif sprites_enemigos.has(objetivo) and is_instance_valid(objetivo):
		return sprites_enemigos[objetivo]
	return null

func mostrar_numero_flotante(objetivo: CharacterStats, cantidad: int, tipo: String):
	var nodo = _obtener_nodo_visual(objetivo)
	if nodo:
		ui.mostrar_numero_flotante(nodo, cantidad, tipo)

func animar_parpadeo_enemigo(enemigo: CharacterStats):
	if is_instance_valid(enemigo) and sprites_enemigos.has(enemigo) and is_instance_valid(sprites_enemigos[enemigo]):
		ui.animar_parpadeo_enemigo(sprites_enemigos[enemigo])

# ===== SELECCIÓN DE OBJETIVO POR AGGRO =====
func obtener_objetivo_por_aggro(objetivos_posibles: Array) -> CharacterStats:
	var provocadores = objetivos_posibles.filter(func(obj): return is_instance_valid(obj) and obj.turnos_provocacion > 0)
	if provocadores.size() > 0:
		return provocadores.pick_random()
	var total_aggro = 0.0
	for obj in objetivos_posibles:
		if is_instance_valid(obj):
			total_aggro += obj.tasa_objetivo
	var rand_val = randf() * total_aggro
	var acumulado = 0.0
	for obj in objetivos_posibles:
		if is_instance_valid(obj):
			acumulado += obj.tasa_objetivo
			if rand_val <= acumulado:
				return obj
	return objetivos_posibles[0]
