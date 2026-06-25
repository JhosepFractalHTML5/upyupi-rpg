extends Node

# --- LUCHADORES (PARTY Y OLEADAS) ---
@export var party_jugador: Array[CharacterStats]
@export var oleadas_enemigos: Array

var enemigos_actuales: Array[CharacterStats] = []
var combatientes: Array[CharacterStats] = []
var turno_actual: int = 0
var indice_oleada: int = 0

# --- REFERENCIAS A LA GUI ---
@onready var menu_acciones = $CapaGUI/MenuAcciones
@onready var btn_atacar = $CapaGUI/MenuAcciones/BtnAtacar
@onready var btn_defender = $CapaGUI/MenuAcciones/BtnDefender
@onready var btn_habilidades = $CapaGUI/MenuAcciones/BtnHabilidades
@onready var btn_items = $CapaGUI/MenuAcciones/BtnItems
@onready var btn_huir = $CapaGUI/MenuAcciones/BtnHuir
@onready var texto_log = $CapaGUI/PanelLog/TextoLog
@onready var contenedor_party = $CapaGUI/ContenedorParty
@onready var contenedor_enemigos = $CapaGUI/ContenedorEnemigos
@onready var retrato_activo = $CapaGUI/MenuAcciones/RetratoActivo 

@onready var panel_accion = $CapaGUI/PanelAccion
@onready var lbl_narrativa = $CapaGUI/PanelAccion/VBox/LblNarrativa
@onready var grid_habilidades = $CapaGUI/PanelAccion/VBox/GridHabilidades

# --- VARIABLES DE SELECCIÓN ---
var seleccionando_objetivo: bool = false
var indice_objetivo_actual: int = 0
var accion_pendiente: String = "" 
var habilidad_pendiente: Habilidad = null 
var sprites_enemigos: Dictionary = {} 

func _ready():
	randomize()
	menu_acciones.show()
	panel_accion.show()
	
	var botones_menu = [btn_atacar, btn_defender, btn_habilidades, btn_items, btn_huir]
	for btn in botones_menu:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	btn_atacar.pressed.connect(_on_btn_atacar_pressed)
	btn_defender.pressed.connect(_on_btn_defender_pressed)
	btn_habilidades.pressed.connect(_on_btn_habilidades_pressed)
	btn_huir.pressed.connect(_on_btn_huir_pressed)
	
	iniciar_batalla()

func _process(_delta):
	if seleccionando_objetivo and enemigos_actuales.size() > 0:
		if indice_objetivo_actual >= enemigos_actuales.size():
			indice_objetivo_actual = 0
			
		var objetivo_actual = enemigos_actuales[indice_objetivo_actual]
		
		for enemigo in sprites_enemigos.keys():
			var sprite = sprites_enemigos[enemigo]
			if enemigo.pv_actuales > 0:
				if enemigo == objetivo_actual:
					sprite.modulate.a = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6)
				else:
					sprite.modulate.a = 1.0

# --- CONTROL VISUAL DEL MENÚ Y NARRATIVA ---

func set_menu_activo(activo: bool):
	btn_atacar.disabled = not activo
	btn_defender.disabled = not activo
	btn_habilidades.disabled = not activo
	btn_items.disabled = not activo
	btn_huir.disabled = not activo
	if activo: btn_atacar.grab_focus()

func narrar(texto: String):
	grid_habilidades.hide()
	lbl_narrativa.show()
	lbl_narrativa.text = texto

# --- PREPARACIÓN DE LA BATALLA ---

func iniciar_batalla():
	for heroe in party_jugador:
		heroe.pt_actuales = 0
		heroe.turnos_provocacion = 0
		heroe.turnos_mejora_defensa = 0
		heroe.cooldowns_actuales.clear()
		
	agregar_al_log("[SISTEMA] Combate Iniciado.") 
	actualizar_interfaz_party()
	cargar_oleada(0)

func cargar_oleada(indice: int):
	indice_oleada = indice
	enemigos_actuales.clear() 
	
	for enemigo_plantilla in oleadas_enemigos[indice]:
		var enemigo_clon = enemigo_plantilla.duplicate(true)
		enemigos_actuales.append(enemigo_clon) 
		
	agregar_al_log("[SISTEMA] Oleada " + str(indice + 1) + " en curso.")
	narrar("¡Comienza la oleada " + str(indice + 1) + "!")
	actualizar_sprites_enemigos()
	
	await get_tree().create_timer(1.5).timeout 
	iniciar_ronda()

func actualizar_sprites_enemigos():
	for hijo in contenedor_enemigos.get_children(): hijo.queue_free()
	sprites_enemigos.clear()
	
	for enemigo in enemigos_actuales:
		var rect = TextureRect.new()
		rect.texture = enemigo.textura_sprite
		contenedor_enemigos.add_child(rect)
		sprites_enemigos[enemigo] = rect 

func iniciar_ronda():
	combatientes.clear()
	turno_actual = 0
	
	for heroe in party_jugador:
		if heroe.pv_actuales > 0: combatientes.append(heroe)
	for enemigo in enemigos_actuales:
		if enemigo.pv_actuales > 0: combatientes.append(enemigo)
			
	combatientes.sort_custom(_ordenar_por_agilidad)
	iniciar_turno()

func _ordenar_por_agilidad(a: CharacterStats, b: CharacterStats) -> bool:
	return a.agilidad > b.agilidad

func obtener_objetivo(es_jugador: bool) -> CharacterStats:
	if es_jugador:
		return enemigos_actuales.pick_random()
	else:
		var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
		var provocadores = heroes_vivos.filter(func(h): return h.turnos_provocacion > 0)
		if provocadores.size() > 0:
			return provocadores.pick_random() 
		return heroes_vivos.pick_random()

# --- CONTROL DE TURNOS Y GESTIÓN DE ESTADOS ---

func iniciar_turno():
	var atacante = combatientes[turno_actual]
	var perdio_provocacion = false
	
	if atacante.turnos_provocacion > 0: 
		atacante.turnos_provocacion -= 1
		if atacante.turnos_provocacion == 0: perdio_provocacion = true
			
	if atacante.turnos_mejora_defensa > 0: atacante.turnos_mejora_defensa -= 1
	
	if party_jugador.has(atacante):
		for hab in atacante.cooldowns_actuales.keys():
			if atacante.cooldowns_actuales[hab] > 0: atacante.cooldowns_actuales[hab] -= 1
	
	if atacante.esta_defendiendo:
		atacante.esta_defendiendo = false
	
	if perdio_provocacion:
		narrar(atacante.nombre + " ya no quiere ser el centro de los golpes.")
		agregar_al_log("[ESTADO] " + atacante.nombre + " -/> Escudo Humano")
		await get_tree().create_timer(1.5).timeout 
	
	if enemigos_actuales.has(atacante):
		set_menu_activo(false)
		narrar("Turno de " + atacante.nombre + ".")
		_ejecutar_ia_enemigo(atacante)
	else:
		retrato_activo.texture = atacante.retrato_base
		narrar("¿Qué hará " + atacante.nombre + "?")
		set_menu_activo(true)

# --- ACCIONES DEL JUGADOR (GUI) ---

func _on_btn_atacar_pressed():
	set_menu_activo(false)
	accion_pendiente = "ATACAR"
	iniciar_seleccion_objetivo()

func _on_btn_defender_pressed():
	set_menu_activo(false)
	var atacante = combatientes[turno_actual]
	
	atacante.esta_defendiendo = true
	var recuperacion = int((atacante.ph_maximos * 0.05) + 5)
	atacante.ph_actuales = min(atacante.ph_actuales + recuperacion, atacante.ph_maximos)
	atacante.pt_actuales = min(atacante.pt_actuales + 35, atacante.pt_maximos)
	atacante.chance_contraataque += 1.5
	
	agregar_al_log("[ACCIÓN] " + atacante.nombre + " usó Defensa (+35 PT).")
	narrar("¡" + atacante.nombre + " adopta una postura defensiva!")
	actualizar_interfaz_party()
	pasar_turno()

func _on_btn_huir_pressed():
	set_menu_activo(false)
	narrar("¡Intentas escapar de la batalla!")

# --- SISTEMA DE SUBMENÚS (HABILIDADES) ---

func _on_btn_habilidades_pressed():
	set_menu_activo(false)
	lbl_narrativa.hide()
	grid_habilidades.show() 
	
	var atacante = combatientes[turno_actual]
	for hijo in grid_habilidades.get_children(): hijo.queue_free()
		
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
			
			var turnos_cd = 0
			if atacante.cooldowns_actuales.has(hab): turnos_cd = atacante.cooldowns_actuales[hab]
				
			if turnos_cd > 0:
				btn.text = hab.nombre + " (CD: " + str(turnos_cd) + ")"
				btn.modulate = Color(0.6, 0.6, 0.6) 
			else:
				btn.text = hab.nombre + " (" + str(hab.costo_ph) + "PH|" + str(hab.costo_pt) + "PT)"
			
			btn.pressed.connect(func(): _seleccionar_habilidad(hab))
			grid_habilidades.add_child(btn)
			if primer_boton == null: primer_boton = btn
			
	if primer_boton != null:
		primer_boton.grab_focus() 
	else:
		narrar("No hay habilidades desbloqueadas.")
		await get_tree().create_timer(1.0).timeout
		set_menu_activo(true)

func _seleccionar_habilidad(hab: Habilidad):
	var atacante = combatientes[turno_actual]
	
	var turnos_cd = 0
	if atacante.cooldowns_actuales.has(hab): turnos_cd = atacante.cooldowns_actuales[hab]
	
	if turnos_cd > 0:
		grid_habilidades.hide()
		narrar("¡" + hab.nombre + " aún se está recargando! (" + str(turnos_cd) + " turnos)")
		await get_tree().create_timer(1.2).timeout
		narrar("¿Qué hará " + atacante.nombre + "?") 
		set_menu_activo(true)
		return 

	if atacante.ph_actuales >= hab.costo_ph and atacante.pt_actuales >= hab.costo_pt:
		habilidad_pendiente = hab
		grid_habilidades.hide() 
		accion_pendiente = "HABILIDAD"
		
		# --- REDIRECCIÓN DE HABILIDADES AUTÓNOMAS ---
		if hab.objetivo == "usuario" or hab.objetivo == "aleatorio": 
			_ejecutar_habilidad_automatica(atacante)
		else: 
			iniciar_seleccion_objetivo()
	else:
		grid_habilidades.hide()
		narrar("¡Recursos insuficientes!")
		await get_tree().create_timer(1.0).timeout
		narrar("¿Qué hará " + atacante.nombre + "?")
		set_menu_activo(true)

func _ejecutar_habilidad_automatica(atacante):
	atacante.gastar_ph(habilidad_pendiente.costo_ph)
	atacante.pt_actuales -= habilidad_pendiente.costo_pt
	
	if habilidad_pendiente.cooldown > 0:
		atacante.cooldowns_actuales[habilidad_pendiente] = habilidad_pendiente.cooldown
		
	actualizar_interfaz_party()
	narrar("¡" + atacante.nombre + " usa " + habilidad_pendiente.nombre + "!")
	await get_tree().create_timer(1.0).timeout
	
	# --- LÓGICA DE ESCUDO HUMANO ---
	if habilidad_pendiente.efecto_especial == "escudo_humano":
		if randf() > 0.10: 
			var duracion = randi_range(2, 3) 
			atacante.turnos_provocacion = duracion 
			atacante.turnos_mejora_defensa = duracion 
			
			narrar(atacante.nombre + " es ahora el centro de golpes por " + str(duracion) + " turnos!!!")
			agregar_al_log("[ESTADO] " + atacante.nombre + " -> Escudo Humano")
		else:
			narrar("¡Pero falló!")
			agregar_al_log("[SISTEMA] " + atacante.nombre + " falló Escudo Humano.")
			
		await get_tree().create_timer(1.5).timeout
		pasar_turno()
		
	# --- LÓGICA DE CORTE MÚLTIPLE MEJORADA (3 Pares de Golpes Aleatorios) ---
	elif habilidad_pendiente.efecto_especial == "corte_multiple":
		narrar("¡" + atacante.nombre + " corta sin piedad al enemigo!!!")
		await get_tree().create_timer(1.0).timeout
		
		# Hacemos 3 "secuencias" de ataque
		for secuencia in range(3):
			# Filtramos quién está vivo ANTES de cada par de golpes
			var vivos = enemigos_actuales.filter(func(e): return e.pv_actuales > 0)
			if vivos.is_empty(): 
				break # Si ya limpió la pantalla, detenemos el ataque por completo
				
			# Elegimos a un enemigo (puede ser el mismo de la secuencia anterior por RNG)
			var defensor = vivos.pick_random()
			
			# Le damos 2 tajos a ese enemigo elegido
			for golpe in range(2):
				if defensor.pv_actuales <= 0: 
					break # Si murió en el primer tajo, frenamos el combo contra él y pasamos a la siguiente secuencia
				
				# Fórmula exacta de la imagen: (ATK * 4) - DEF
				var defensa_real = defensor.defensa
				if defensor.turnos_mejora_defensa > 0: defensa_real = int(defensa_real * 1.5)
				
				var dano_calculado = (atacante.ataque * 4) - defensa_real
				var dano_final = max(1, dano_calculado)
				if defensor.esta_defendiendo: dano_final = int(dano_final * 0.55)
				
				defensor.recibir_dano(dano_final)
				agregar_al_log("[CORTE MÚLTIPLE " + str(secuencia+1) + "/3] " + atacante.nombre + " -> " + defensor.nombre + " (-" + str(dano_final) + " PV)")
				
				# Efecto visual de daño
				var sprite = sprites_enemigos[defensor]
				sprite.modulate = Color(3, 0.5, 0.5) 
				var tween = get_tree().create_tween()
				tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
				
				await get_tree().create_timer(0.25).timeout # Micro pausa entre tajos
				
				# Comprobamos si el tajo mató al enemigo
				var batalla_sigue = await verificar_estado_batalla(defensor, false)
				if not batalla_sigue: 
					return # Si el tajo mató al último enemigo vivo, fin del combate inmediato
					
		# Una vez que terminan las 3 secuencias de 2 golpes (o si ya no hay enemigos), pasamos turno
		pasar_turno()

# --- SISTEMA DE SELECCIÓN DE OBJETIVO MANUAL ---

func iniciar_seleccion_objetivo():
	seleccionando_objetivo = true
	indice_objetivo_actual = 0
	narrar("Selecciona un objetivo...")
	
func _unhandled_input(event):
	if grid_habilidades.visible and event.is_action_pressed("ui_cancel"):
		grid_habilidades.hide()
		narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
		set_menu_activo(true)
		get_viewport().set_input_as_handled() 
		return
		
	if not seleccionando_objetivo: return
	
	if event.is_action_pressed("ui_right"):
		indice_objetivo_actual += 1
		if indice_objetivo_actual >= enemigos_actuales.size(): indice_objetivo_actual = 0 
	elif event.is_action_pressed("ui_left"):
		indice_objetivo_actual -= 1
		if indice_objetivo_actual < 0: indice_objetivo_actual = enemigos_actuales.size() - 1 
	elif event.is_action_pressed("ui_accept"): 
		confirmar_seleccion()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"): 
		cancelar_seleccion()
		get_viewport().set_input_as_handled()

func cancelar_seleccion():
	seleccionando_objetivo = false
	for enemigo in sprites_enemigos.keys():
		if enemigo.pv_actuales > 0: sprites_enemigos[enemigo].modulate.a = 1.0
	narrar("¿Qué hará " + combatientes[turno_actual].nombre + "?")
	set_menu_activo(true)

func confirmar_seleccion():
	seleccionando_objetivo = false
	var atacante = combatientes[turno_actual]
	
	if indice_objetivo_actual >= enemigos_actuales.size(): indice_objetivo_actual = 0
	var defensor = enemigos_actuales[indice_objetivo_actual]
	
	for enemigo in sprites_enemigos.keys():
		if enemigo.pv_actuales > 0: sprites_enemigos[enemigo].modulate.a = 1.0
		
	if accion_pendiente == "ATACAR":
		narrar("¡" + atacante.nombre + " ataca a " + defensor.nombre + "!")
		atacante.pt_actuales = min(atacante.pt_actuales + 20, atacante.pt_maximos)
		await get_tree().create_timer(0.8).timeout 
		_ejecutar_ataque_normal(atacante, defensor)
	
	elif accion_pendiente == "HABILIDAD":
		atacante.gastar_ph(habilidad_pendiente.costo_ph)
		atacante.pt_actuales -= habilidad_pendiente.costo_pt 
		if habilidad_pendiente.cooldown > 0:
			atacante.cooldowns_actuales[habilidad_pendiente] = habilidad_pendiente.cooldown
			
		actualizar_interfaz_party()
		narrar("¡" + atacante.nombre + " usa " + habilidad_pendiente.nombre + "!")
		await get_tree().create_timer(0.8).timeout
		
		if habilidad_pendiente.es_ataque_atipico: _ejecutar_ataque_atipico(atacante, defensor)
		else: _ejecutar_ataque_normal(atacante, defensor)

# --- INTELIGENCIA ARTIFICIAL DEL ENEMIGO ---
func _ejecutar_ia_enemigo(atacante):
	var defensor = obtener_objetivo(false) 
	var probabilidad = randi() % 100 
	await get_tree().create_timer(0.8).timeout
	
	if probabilidad < 60:
		narrar("¡" + atacante.nombre + " ataca a " + defensor.nombre + "!")
		await get_tree().create_timer(0.8).timeout
		_ejecutar_ataque_normal(atacante, defensor)
	elif probabilidad < 90:
		narrar("¡" + atacante.nombre + " usa un ataque especial!")
		await get_tree().create_timer(0.8).timeout
		_ejecutar_ataque_atipico(atacante, defensor)
	else:
		narrar("¡" + atacante.nombre + " tropezó y falló!")
		pasar_turno()

# --- FÓRMULAS DE DAÑO Y CONTRAATAQUE ---
func _ejecutar_ataque_normal(atacante, defensor):
	var defensa_real = defensor.defensa
	if defensor.turnos_mejora_defensa > 0: defensa_real = int(defensa_real * 1.5)
	
	var dano_calculado = (atacante.ataque * 4) - (defensa_real * 2)
	var dano_final = max(1, dano_calculado)
	
	if defensor.esta_defendiendo:
		dano_final = int(dano_final * 0.55) 
	
	defensor.recibir_dano(dano_final)
	agregar_al_log("[DAÑO] " + atacante.nombre + " -> " + defensor.nombre + " (-" + str(dano_final) + " PV)")
	
	if party_jugador.has(defensor) and defensor.pv_actuales > 0:
		defensor.chance_contraataque += 0.01
		if (randf() * 100.0) < defensor.chance_contraataque:
			narrar("¡" + defensor.nombre + " reacciona con un contraataque!")
			defensor.chance_contraataque = 0.0 
			await get_tree().create_timer(1.0).timeout
			_ejecutar_ataque_normal(defensor, atacante) 
			return 
	await verificar_estado_batalla(defensor)

func _ejecutar_ataque_atipico(atacante, defensor):
	var defensa_real = defensor.defensa_atipica
	if defensor.turnos_mejora_defensa > 0: defensa_real = int(defensa_real * 1.5)
		
	var dano_calculado = (atacante.ataque_atipico * 4) - (defensa_real * 2)
	var dano_final = max(1, dano_calculado)
	
	if defensor.esta_defendiendo:
		dano_final = int(dano_final * 0.55)
	
	defensor.recibir_dano(dano_final)
	agregar_al_log("[DAÑO ATÍPICO] " + atacante.nombre + " -> " + defensor.nombre + " (-" + str(dano_final) + " PV)")
	
	if party_jugador.has(defensor) and defensor.pv_actuales > 0:
		defensor.chance_contraataque += 0.01
		if (randf() * 100.0) < defensor.chance_contraataque:
			narrar("¡" + defensor.nombre + " reacciona con un contraataque!")
			defensor.chance_contraataque = 0.0
			await get_tree().create_timer(1.0).timeout
			_ejecutar_ataque_normal(defensor, atacante)
			return
	await verificar_estado_batalla(defensor)

# --- RESOLUCIÓN ---
func verificar_estado_batalla(defensor, pasar_el_turno: bool = true) -> bool:
	actualizar_interfaz_party() 
	
	if defensor.pv_actuales <= 0:
		narrar("¡" + defensor.nombre + " ha caído!")
		await get_tree().create_timer(1.0).timeout 
		
		if enemigos_actuales.has(defensor):
			var sprite_muerto = sprites_enemigos[defensor]
			var tween = get_tree().create_tween()
			tween.tween_property(sprite_muerto, "modulate:a", 0.0, 0.5) 
			enemigos_actuales.erase(defensor)
			
			if enemigos_actuales.is_empty():
				_procesar_fin_oleada()
				return false # Retorna false indicando que la oleada acabó
		elif party_jugador.has(defensor):
			var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
			if heroes_vivos.is_empty():
				narrar("El grupo ha sido aniquilado...")
				return false
				
	if pasar_el_turno:
		pasar_turno()
		
	return true # Retorna true indicando que todo sigue normal

func _procesar_fin_oleada():
	indice_oleada += 1
	if indice_oleada < oleadas_enemigos.size():
		await get_tree().create_timer(1.0).timeout
		cargar_oleada(indice_oleada)
	else:
		narrar("¡Victoria total!")

func pasar_turno():
	turno_actual += 1
	if turno_actual >= combatientes.size():
		narrar("¡El ayudante interviene para apoyarlos!")
		await get_tree().create_timer(1.2).timeout
		iniciar_ronda() 
	else:
		if combatientes[turno_actual].pv_actuales <= 0:
			pasar_turno()
			return
		await get_tree().create_timer(0.8).timeout
		iniciar_turno()

# --- INTERFAZ ---
func actualizar_interfaz_party():
	var paneles = contenedor_party.get_children()
	for i in range(paneles.size()):
		if i < party_jugador.size():
			var heroe = party_jugador[i]
			paneles[i].show()
			paneles[i].find_child("LblNombre").text = heroe.nombre
			paneles[i].find_child("LblPV").text = "PV: " + str(heroe.pv_actuales) + "/" + str(heroe.pv_maximos)
			paneles[i].find_child("LblPH").text = "PH: " + str(heroe.ph_actuales) + "/" + str(heroe.ph_maximos)
			
			var lbl_pt = paneles[i].find_child("LblPT")
			if lbl_pt: lbl_pt.text = "PT: " + str(heroe.pt_actuales) + "/" + str(heroe.pt_maximos)
		else:
			paneles[i].hide()

func agregar_al_log(mensaje: String):
	print(mensaje) 
	texto_log.append_text(mensaje + "\n")
