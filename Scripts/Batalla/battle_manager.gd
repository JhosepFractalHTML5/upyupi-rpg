extends Node

@export var party_jugador: Array[CharacterStats]
@export var oleadas_enemigos: Array

var enemigos_actuales: Array[CharacterStats] = []
var combatientes: Array[CharacterStats] = []
var turno_actual: int = 0
var indice_oleada: int = 0

@onready var ui: BattleUI = $CapaGUI

var seleccionando_objetivo: bool = false
var indice_objetivo_actual: int = 0
var accion_pendiente: String = "" 
var habilidad_pendiente: Habilidad = null 
var sprites_enemigos: Dictionary = {} 

func _ready():
	randomize()
	ui.btn_atacar.pressed.connect(_on_btn_atacar_pressed)
	ui.btn_defender.pressed.connect(_on_btn_defender_pressed)
	ui.btn_habilidades.pressed.connect(_on_btn_habilidades_pressed)
	ui.btn_huir.pressed.connect(_on_btn_huir_pressed)
	iniciar_batalla()

func _process(_delta):
	if not seleccionando_objetivo: return
	
	var es_apuntado_aliado = (accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado")
	
	if es_apuntado_aliado:
		for enemigo in sprites_enemigos.keys(): sprites_enemigos[enemigo].modulate.a = 1.0
		var paneles = ui.contenedor_party.get_children()
		for i in range(paneles.size()):
			if i < party_jugador.size():
				paneles[i].modulate.a = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6) if i == indice_objetivo_actual else 1.0
	else:
		for p in ui.contenedor_party.get_children(): p.modulate.a = 1.0
		if enemigos_actuales.size() > 0:
			if indice_objetivo_actual >= enemigos_actuales.size(): indice_objetivo_actual = 0
			var objetivo_actual = enemigos_actuales[indice_objetivo_actual]
			for enemigo in sprites_enemigos.keys():
				if enemigo.pv_actuales > 0:
					sprites_enemigos[enemigo].modulate.a = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6) if enemigo == objetivo_actual else 1.0

# --- PREPARACIÓN DE LA BATALLA ---
func iniciar_batalla():
	for heroe in party_jugador:
		# --- NUEVO: PT aleatorios entre 0 y el máximo de cada héroe ---
		heroe.pt_actuales = randi_range(0, heroe.pt_maximos)
		
		heroe.turnos_provocacion = 0
		heroe.turnos_mejora_defensa = 0
		heroe.turnos_mejora_ataque = 0 
		heroe.turnos_mejora_agilidad = 0 
		heroe.turnos_distraido = 0
		heroe.turnos_agilidad_baja = 0
		heroe.dano_recibido_esta_ronda = 0
		heroe.cooldowns_actuales.clear()
		
	ui.agregar_al_log("[SISTEMA] Combate Iniciado.") 
	ui.actualizar_interfaz_party(party_jugador)
	cargar_oleada(0)

func cargar_oleada(indice: int):
	indice_oleada = indice
	enemigos_actuales.clear() 
	
	var index_enemigo = 1
	for enemigo_plantilla in oleadas_enemigos[indice]:
		var enemigo_clon = enemigo_plantilla.duplicate(true)
		
		# --- CORRECCIÓN: Respetar el nombre original ---
		var nombre_base = enemigo_plantilla.nombre
		if nombre_base == "": nombre_base = "Enemigo" # Por si te olvidas de ponerle nombre
		
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
	for hijo in ui.contenedor_enemigos.get_children(): hijo.queue_free()
	sprites_enemigos.clear()
	for enemigo in enemigos_actuales:
		var rect = TextureRect.new()
		rect.texture = enemigo.textura_sprite
		ui.contenedor_enemigos.add_child(rect)
		sprites_enemigos[enemigo] = rect 

func iniciar_ronda():
	combatientes.clear()
	turno_actual = 0
	for heroe in party_jugador: if heroe.pv_actuales > 0: combatientes.append(heroe)
	for enemigo in enemigos_actuales: if enemigo.pv_actuales > 0: combatientes.append(enemigo)
			
	combatientes.sort_custom(_ordenar_por_agilidad)
	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)
	iniciar_turno()

func _ordenar_por_agilidad(a: CharacterStats, b: CharacterStats) -> bool:
	var agi_a = a.agilidad / 2 if a.turnos_agilidad_baja > 0 else a.agilidad
	if a.turnos_mejora_agilidad > 0: agi_a = int(agi_a * 1.5) # <-- NUEVO
	var agi_b = b.agilidad / 2 if b.turnos_agilidad_baja > 0 else b.agilidad
	if b.turnos_mejora_agilidad > 0: agi_b = int(agi_b * 1.5) # <-- NUEVO
	return agi_a > agi_b

# --- CONTROL DE TURNOS ---
func iniciar_turno():
	var atacante = combatientes[turno_actual]
	var perdio_provocacion = false
	var perdio_distraccion = false
	
	if atacante.turnos_provocacion > 0: 
		atacante.turnos_provocacion -= 1
		if atacante.turnos_provocacion == 0: perdio_provocacion = true
			
	if atacante.turnos_mejora_defensa > 0: atacante.turnos_mejora_defensa -= 1
	if atacante.turnos_mejora_ataque > 0: atacante.turnos_mejora_ataque -= 1 # <-- NUEVO
	if atacante.turnos_mejora_agilidad > 0: atacante.turnos_mejora_agilidad -= 1 # <-- NUEVO
	if atacante.turnos_agilidad_baja > 0: atacante.turnos_agilidad_baja -= 1
	
	if atacante.turnos_distraido > 0:
		atacante.turnos_distraido -= 1
		if atacante.turnos_distraido == 0: perdio_distraccion = true
	
	if party_jugador.has(atacante):
		for hab in atacante.cooldowns_actuales.keys():
			if atacante.cooldowns_actuales[hab] > 0: atacante.cooldowns_actuales[hab] -= 1
	
	if atacante.esta_defendiendo: atacante.esta_defendiendo = false
		
	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador)
	
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
		await atacante.ejecutar_ia(self, party_jugador) # --- DELEGACIÓN DE IA ---
	else:
		ui.retrato_activo.texture = atacante.retrato_base
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)

# --- ACCIONES DEL JUGADOR ---
func _on_btn_atacar_pressed():
	ui.set_menu_activo(false)
	accion_pendiente = "ATACAR"
	iniciar_seleccion_objetivo()

func _on_btn_defender_pressed():
	ui.set_menu_activo(false)
	var atacante = combatientes[turno_actual]
	atacante.esta_defendiendo = true
	var recuperacion = int((atacante.ph_maximos * 0.05) + 5)
	atacante.ph_actuales = min(atacante.ph_actuales + recuperacion, atacante.ph_maximos)
	atacante.pt_actuales = min(atacante.pt_actuales + 35, atacante.pt_maximos)
	atacante.chance_contraataque += 1.5
	
	ui.agregar_al_log("[ACCIÓN] " + atacante.nombre + " usó Defensa (+35 PT).")
	ui.narrar("¡" + atacante.nombre + " adopta una postura defensiva!")
	ui.actualizar_interfaz_party(party_jugador)
	pasar_turno()

func _on_btn_huir_pressed():
	ui.set_menu_activo(false)
	ui.narrar("¡Intentas escapar de la batalla!")

# --- SISTEMA DE HABILIDADES ---
func _on_btn_habilidades_pressed():
	ui.set_menu_activo(false)
	ui.lbl_narrativa.hide()
	ui.grid_habilidades.show() 
	
	var atacante = combatientes[turno_actual]
	for hijo in ui.grid_habilidades.get_children(): hijo.queue_free()
		
	var claves_desbloqueo = [
		atacante.item_clave_hab_1, atacante.item_clave_hab_2,
		atacante.item_clave_hab_3, atacante.item_clave_hab_4,
		atacante.item_clave_hab_5, atacante.item_clave_hab_6
	]
	var primer_boton: Button = null 
	
	for i in range(atacante.habilidades_disponibles.size()):
		if i < 6 and claves_desbloqueo[i] == true:
			var hab = atacante.habilidades_disponibles[i]
			var btn = Button.new()
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var turnos_cd = atacante.cooldowns_actuales[hab] if atacante.cooldowns_actuales.has(hab) else 0
				
			if turnos_cd > 0:
				btn.text = hab.nombre + " (CD: " + str(turnos_cd) + ")"
				btn.modulate = Color(0.6, 0.6, 0.6) 
			elif atacante.turnos_distraido > 0 and hab.es_ataque_fuerte:
				btn.text = hab.nombre + " (BLOQUEADO)"
				btn.modulate = Color(0.8, 0.4, 0.4) 
			else:
				btn.text = hab.nombre + " (" + str(hab.costo_ph) + "PH|" + str(hab.costo_pt) + "PT)"
			
			btn.pressed.connect(func(): _seleccionar_habilidad(hab))
			ui.grid_habilidades.add_child(btn)
			if primer_boton == null: primer_boton = btn
			
	if primer_boton != null:
		primer_boton.grab_focus() 
	else:
		ui.narrar("No hay habilidades desbloqueadas.")
		await get_tree().create_timer(1.0).timeout
		ui.set_menu_activo(true)

func _seleccionar_habilidad(hab: Habilidad):
	var atacante = combatientes[turno_actual]
	var turnos_cd = atacante.cooldowns_actuales[hab] if atacante.cooldowns_actuales.has(hab) else 0
	
	if turnos_cd > 0:
		ui.grid_habilidades.hide()
		ui.narrar("¡" + hab.nombre + " aún se está recargando! (" + str(turnos_cd) + " turnos)")
		await get_tree().create_timer(1.2).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?") 
		ui.set_menu_activo(true)
		return 
		
	if atacante.turnos_distraido > 0 and hab.es_ataque_fuerte:
		ui.grid_habilidades.hide()
		ui.narrar("¡" + atacante.nombre + " está muy distraído para concentrarse en eso!")
		await get_tree().create_timer(1.5).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?") 
		ui.set_menu_activo(true)
		return

	if atacante.ph_actuales >= hab.costo_ph and atacante.pt_actuales >= hab.costo_pt:
		habilidad_pendiente = hab
		ui.grid_habilidades.hide() 
		accion_pendiente = "HABILIDAD"
		
		# --- CORRECCIÓN: Lista de habilidades que no requieren apuntar manualmente ---
		var objs_automaticos = ["usuario", "aleatorio_enemigos", "aleatorio_aliados", "todos_enemigos", "todos_aliados"]
		
		if hab.objetivo in objs_automaticos: 
			_ejecutar_habilidad_preparada(atacante, null) 
		else: 
			iniciar_seleccion_objetivo()
	else:
		ui.grid_habilidades.hide()
		ui.narrar("¡Recursos insuficientes!")
		await get_tree().create_timer(1.0).timeout
		ui.narrar("¿Qué hará " + atacante.nombre + "?")
		ui.set_menu_activo(true)

func _ejecutar_habilidad_preparada(atacante: CharacterStats, defensor: CharacterStats):
	atacante.gastar_ph(habilidad_pendiente.costo_ph)
	atacante.pt_actuales -= habilidad_pendiente.costo_pt 
	if habilidad_pendiente.cooldown > 0:
		atacante.cooldowns_actuales[habilidad_pendiente] = habilidad_pendiente.cooldown
	ui.actualizar_interfaz_party(party_jugador)
	await habilidad_pendiente.ejecutar(atacante, defensor, self)

# --- SELECCIÓN DE OBJETIVOS MANUAL ---
func iniciar_seleccion_objetivo():
	seleccionando_objetivo = true
	indice_objetivo_actual = 0
	ui.narrar("Selecciona un aliado de la party..." if (accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado") else "Selecciona un enemigo...")
	
func _unhandled_input(event):
	if ui.grid_habilidades.visible and event.is_action_pressed("ui_cancel"):
		ui.grid_habilidades.hide()
		ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
		ui.set_menu_activo(true)
		get_viewport().set_input_as_handled() 
		return
		
	if not seleccionando_objetivo: return
	
	var max_objetivos = party_jugador.size() if (accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado") else enemigos_actuales.size()
	
	if event.is_action_pressed("ui_right"):
		indice_objetivo_actual = (indice_objetivo_actual + 1) % max_objetivos
	elif event.is_action_pressed("ui_left"):
		indice_objetivo_actual = (indice_objetivo_actual - 1 + max_objetivos) % max_objetivos
	elif event.is_action_pressed("ui_accept"): 
		confirmar_seleccion()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"): 
		cancelar_seleccion()
		get_viewport().set_input_as_handled()

func cancelar_seleccion():
	seleccionando_objetivo = false
	for enemigo in sprites_enemigos.keys(): if enemigo.pv_actuales > 0: sprites_enemigos[enemigo].modulate.a = 1.0
	for p in ui.contenedor_party.get_children(): p.modulate.a = 1.0
	ui.narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
	ui.set_menu_activo(true)

func confirmar_seleccion():
	seleccionando_objetivo = false
	var atacante = combatientes[turno_actual]
	var defensor: CharacterStats = null
	
	if accion_pendiente == "HABILIDAD" and habilidad_pendiente and habilidad_pendiente.objetivo == "aliado":
		if indice_objetivo_actual >= party_jugador.size(): indice_objetivo_actual = 0
		defensor = party_jugador[indice_objetivo_actual]
	else:
		if indice_objetivo_actual >= enemigos_actuales.size(): indice_objetivo_actual = 0
		defensor = enemigos_actuales[indice_objetivo_actual]
	
	for enemigo in sprites_enemigos.keys(): if enemigo.pv_actuales > 0: sprites_enemigos[enemigo].modulate.a = 1.0
	for p in ui.contenedor_party.get_children(): p.modulate.a = 1.0
		
	if accion_pendiente == "ATACAR":
		ui.narrar("¡" + atacante.nombre + " ataca a " + defensor.nombre + "!")
		atacante.pt_actuales = min(atacante.pt_actuales + 20, atacante.pt_maximos)
		await get_tree().create_timer(0.8).timeout 
		await defensor.recibir_ataque(atacante, self) # --- DELEGACIÓN DE DAÑO ---
	elif accion_pendiente == "HABILIDAD":
		_ejecutar_habilidad_preparada(atacante, defensor)

# --- RESOLUCIÓN Y DESPERTAR POR DAÑO ---
func verificar_estado_batalla(defensor, pasar_el_turno: bool = true) -> bool:
	ui.actualizar_interfaz_party(party_jugador) 
	ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador) 
	
	if defensor.pv_actuales <= 0:
		ui.narrar("¡" + defensor.nombre + " ha caído!")
		ui.actualizar_linea_turnos(combatientes, turno_actual, party_jugador) 
		await get_tree().create_timer(1.0).timeout 
		
		if enemigos_actuales.has(defensor):
			var sprite_muerto = sprites_enemigos[defensor]
			var tween = get_tree().create_tween()
			tween.tween_property(sprite_muerto, "modulate:a", 0.0, 0.5) 
			enemigos_actuales.erase(defensor)
			
			if enemigos_actuales.is_empty():
				_procesar_fin_oleada()
				return false 
		elif party_jugador.has(defensor):
			var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
			if heroes_vivos.is_empty():
				ui.narrar("El grupo ha sido aniquilado...")
				return false
				
	if pasar_el_turno: pasar_turno()
	return true 

func _procesar_fin_oleada():
	indice_oleada += 1
	if indice_oleada < oleadas_enemigos.size():
		await get_tree().create_timer(1.0).timeout
		cargar_oleada(indice_oleada)
	else:
		ui.narrar("¡Victoria total!")

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
		if c.pv_actuales > 0 and (c.turnos_distraido > 0 or c.turnos_agilidad_baja > 0):
			if c.dano_recibido_esta_ronda >= (c.pv_maximos * 0.25):
				c.turnos_distraido = 0
				c.turnos_agilidad_baja = 0
				ui.agregar_al_log("[ESTADO] " + c.nombre + " -/> Distraído (Golpe Masivo)")
				ui.narrar("¡El dolor hace que " + c.nombre + " vuelva a concentrarse!")
				alguien_desperto = true
				await get_tree().create_timer(1.5).timeout
		c.dano_recibido_esta_ronda = 0 
		
	if not alguien_desperto:
		ui.narrar("¡El ayudante interviene para apoyarlos!")
		await get_tree().create_timer(1.2).timeout
		
	iniciar_ronda()
