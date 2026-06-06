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

# --- VARIABLES DE SELECCIÓN DE OBJETIVO ---
var seleccionando_objetivo: bool = false
var indice_objetivo_actual: int = 0
var accion_pendiente: String = "" # Guarda si elegimos "ATACAR" o "HABILIDAD"
var sprites_enemigos: Array = [] # Guardará los nodos visuales de los enemigos

func _ready():
	randomize()
	menu_acciones.hide()
	
	btn_atacar.pressed.connect(_on_btn_atacar_pressed)
	btn_defender.pressed.connect(_on_btn_defender_pressed)
	btn_habilidades.pressed.connect(_on_btn_habilidades_pressed)
	btn_huir.pressed.connect(_on_btn_huir_pressed)
	
	iniciar_batalla()

# --- EFECTO VISUAL DE PARPADEO ---
func _process(delta):
	if seleccionando_objetivo and sprites_enemigos.size() > 0:
		for i in range(sprites_enemigos.size()):
			if i == indice_objetivo_actual:
				# Efecto de parpadeo matemático usando el tiempo interno de Godot
				sprites_enemigos[i].modulate.a = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6)
			else:
				sprites_enemigos[i].modulate.a = 1.0 # Los no seleccionados se ven normales

# --- PREPARACIÓN DE LA BATALLA ---

func iniciar_batalla():
	print("¡Inicia el combate!") 
	agregar_al_log("[SISTEMA] Combate Iniciado.") 
	actualizar_interfaz_party()
	cargar_oleada(0)

func cargar_oleada(indice: int):
	indice_oleada = indice
	enemigos_actuales.assign(oleadas_enemigos[indice].duplicate()) 
	print("\n--- ¡COMIENZA LA OLEADA " + str(indice + 1) + "! ---")
	agregar_al_log("[SISTEMA] Oleada " + str(indice + 1) + " en curso.")
	
	actualizar_sprites_enemigos()
	iniciar_ronda()

func actualizar_sprites_enemigos():
	# 1. Borramos los sprites de la oleada anterior o los muertos
	for hijo in contenedor_enemigos.get_children():
		hijo.queue_free()
	sprites_enemigos.clear()
	
	# 2. Creamos nuevos TextureRect por cada enemigo vivo
	for enemigo in enemigos_actuales:
		var rect = TextureRect.new()
		rect.texture = enemigo.textura_sprite
		contenedor_enemigos.add_child(rect)
		sprites_enemigos.append(rect)

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
	print("\n--- Nueva Ronda ---")
	iniciar_turno()

func _ordenar_por_agilidad(a: CharacterStats, b: CharacterStats) -> bool:
	return a.agilidad > b.agilidad

# --- CONTROL DE TURNOS ---

func iniciar_turno():
	var atacante = combatientes[turno_actual]
	
	if atacante.esta_defendiendo:
		atacante.esta_defendiendo = false
		print(atacante.nombre + " baja la guardia para actuar.")
		agregar_al_log("[ESTADO] " + atacante.nombre + " pierde Defensa.")
	
	print("\n--- Turno de " + atacante.nombre + " ---")
	
	if enemigos_actuales.has(atacante):
		menu_acciones.hide()
		_ejecutar_ia_enemigo(atacante)
	else:
		print("Esperando tu orden...")
		menu_acciones.show()
		btn_atacar.grab_focus() 

# --- ACCIONES DEL JUGADOR (GUI) ---

func _on_btn_atacar_pressed():
	menu_acciones.hide()
	accion_pendiente = "ATACAR"
	iniciar_seleccion_objetivo()

func _on_btn_habilidades_pressed():
	var atacante = combatientes[turno_actual]
	if atacante.ph_actuales >= 10:
		menu_acciones.hide()
		accion_pendiente = "HABILIDAD"
		iniciar_seleccion_objetivo()
	else:
		print("¡No tienes suficientes PH!")
		agregar_al_log("[SISTEMA] " + atacante.nombre + " intentó usar Habilidad sin PH.")

func _on_btn_defender_pressed():
	menu_acciones.hide()
	var atacante = combatientes[turno_actual]
	
	atacante.esta_defendiendo = true
	var recuperacion = int((atacante.ph_maximos * 0.05) + 5)
	atacante.ph_actuales += recuperacion
	
	if atacante.ph_actuales > atacante.ph_maximos:
		atacante.ph_actuales = atacante.ph_maximos
		
	atacante.chance_contraataque += 1.5
	
	print("¡" + atacante.nombre + " adopta una postura defensiva!")
	agregar_al_log("[ACCIÓN] " + atacante.nombre + " usó Defensa.")
	agregar_al_log("[RECURSOS] " + atacante.nombre + " recupera " + str(recuperacion) + " PH.")
	actualizar_interfaz_party()
	pasar_turno()

func _on_btn_huir_pressed():
	menu_acciones.hide()
	print("¡Escapas cobardemente de la batalla!")
	agregar_al_log("[SISTEMA] Intento de huida ejecutado.")

# --- SISTEMA DE SELECCIÓN DE OBJETIVO MANUAL ---

func iniciar_seleccion_objetivo():
	seleccionando_objetivo = true
	indice_objetivo_actual = 0
	print("Selecciona un objetivo...")

func _unhandled_input(event):
	# Este código se encarga de escuchar las flechas y la Z cuando estamos apuntando
	if not seleccionando_objetivo: return
	
	if event.is_action_pressed("ui_right"):
		indice_objetivo_actual += 1
		if indice_objetivo_actual >= enemigos_actuales.size():
			indice_objetivo_actual = 0 # Vuelve al primero
			
	elif event.is_action_pressed("ui_left"):
		indice_objetivo_actual -= 1
		if indice_objetivo_actual < 0:
			indice_objetivo_actual = enemigos_actuales.size() - 1 # Va al último
			
	elif event.is_action_pressed("ui_accept"): # Presionar Enter o Z
		confirmar_seleccion()
		
	elif event.is_action_pressed("ui_cancel"): # Presionar Escape o X
		cancelar_seleccion()

func cancelar_seleccion():
	seleccionando_objetivo = false
	# Devolvemos todos los sprites a opacidad normal
	for sprite in sprites_enemigos:
		sprite.modulate.a = 1.0
	
	# Mostramos el menú de nuevo
	menu_acciones.show()
	btn_atacar.grab_focus()

func confirmar_seleccion():
	seleccionando_objetivo = false
	var atacante = combatientes[turno_actual]
	var defensor = enemigos_actuales[indice_objetivo_actual]
	
	# Restauramos la opacidad antes de pegar
	for sprite in sprites_enemigos:
		sprite.modulate.a = 1.0
		
	if accion_pendiente == "ATACAR":
		print("¡" + atacante.nombre + " ataca a " + defensor.nombre + "!")
		_ejecutar_ataque_normal(atacante, defensor)
	
	elif accion_pendiente == "HABILIDAD":
		atacante.gastar_ph(10)
		agregar_al_log("[RECURSOS] " + atacante.nombre + " gasta 10 PH.")
		actualizar_interfaz_party()
		_ejecutar_ataque_atipico(atacante, defensor)

# --- INTELIGENCIA ARTIFICIAL DEL ENEMIGO ---

func _ejecutar_ia_enemigo(atacante):
	# El enemigo sigue eligiendo al azar a un héroe vivo
	var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
	var defensor = heroes_vivos.pick_random()
	
	var probabilidad = randi() % 100 
	await get_tree().create_timer(0.8).timeout
	
	if probabilidad < 60:
		print(atacante.nombre + " decide usar un Ataque Físico contra " + defensor.nombre + ".")
		_ejecutar_ataque_normal(atacante, defensor)
	elif probabilidad < 90:
		print("¡CUIDADO! " + atacante.nombre + " prepara un ATAQUE ATÍPICO contra " + defensor.nombre + "!")
		_ejecutar_ataque_atipico(atacante, defensor)
	else:
		print(atacante.nombre + " intentó atacar, pero tropezó y falló miserablemente.")
		agregar_al_log("[SISTEMA] " + atacante.nombre + " falló su turno.")
		pasar_turno()

# --- FÓRMULAS DE DAÑO ---

func _ejecutar_ataque_normal(atacante, defensor):
	var dano_calculado = (atacante.ataque * 4) - (defensor.defensa * 2)
	var dano_final = max(1, dano_calculado)
	
	if defensor.esta_defendiendo:
		dano_final = int(dano_final * 0.55) 
		print("¡El golpe impacta en la guardia de " + defensor.nombre + "! Daño reducido a " + str(dano_final))
		agregar_al_log("[SISTEMA] " + defensor.nombre + " mitigó daño.")
	
	defensor.recibir_dano(dano_final)
	agregar_al_log("[DAÑO] " + atacante.nombre + " -> " + defensor.nombre + " (-" + str(dano_final) + " PV)")
	verificar_estado_batalla(defensor)

func _ejecutar_ataque_atipico(atacante, defensor):
	var dano_calculado = (atacante.ataque_atipico * 4) - (defensor.defensa_atipica * 2)
	var dano_final = max(1, dano_calculado)
	
	if defensor.esta_defendiendo:
		dano_final = int(dano_final * 0.55)
		agregar_al_log("[SISTEMA] " + defensor.nombre + " mitigó daño especial.")
	
	defensor.recibir_dano(dano_final)
	agregar_al_log("[DAÑO ATÍPICO] " + atacante.nombre + " -> " + defensor.nombre + " (-" + str(dano_final) + " PV)")
	verificar_estado_batalla(defensor)

# --- RESOLUCIÓN DEL TURNO Y OLEADAS ---

func verificar_estado_batalla(defensor):
	actualizar_interfaz_party() # Actualiza PV en pantalla al instante
	
	if defensor.pv_actuales <= 0:
		print("\n¡" + defensor.nombre + " ha caído!")
		agregar_al_log("[CAÍDA] " + defensor.nombre + " ha llegado a 0 PV.")
		
		if enemigos_actuales.has(defensor):
			enemigos_actuales.erase(defensor)
			actualizar_sprites_enemigos() # Borra el sprite del enemigo muerto al instante
			
			if enemigos_actuales.is_empty():
				_procesar_fin_oleada()
				return 
				
		elif party_jugador.has(defensor):
			var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
			if heroes_vivos.is_empty():
				print("\n--- FIN DEL JUEGO. Tu grupo ha sido derrotado. ---")
				agregar_al_log("[SISTEMA] GAME OVER. Party Derrotada.")
				return
				
	pasar_turno()

func _procesar_fin_oleada():
	print("\n¡Oleada " + str(indice_oleada + 1) + " superada!")
	agregar_al_log("[SISTEMA] Oleada limpiada con éxito.")
	indice_oleada += 1
	
	if indice_oleada < oleadas_enemigos.size():
		await get_tree().create_timer(1.5).timeout
		cargar_oleada(indice_oleada)
	else:
		print("\n¡VICTORIA TOTAL! Has limpiado todas las oleadas.")
		agregar_al_log("[SISTEMA] COMBATE SUPERADO. Victoria Total.")

func pasar_turno():
	turno_actual += 1
	
	if turno_actual >= combatientes.size():
		print("\n[NPC Ayudante]: ¡Sigan luchando, los estoy cubriendo!")
		agregar_al_log("[ACCIÓN] NPC Ayudante interviene en la ronda.")
		
		await get_tree().create_timer(1.0).timeout
		iniciar_ronda() 
	else:
		if combatientes[turno_actual].pv_actuales <= 0:
			pasar_turno()
			return
			
		await get_tree().create_timer(1.0).timeout
		iniciar_turno()

# --- INTERFAZ DE LA PARTY ---
func actualizar_interfaz_party():
	var paneles = contenedor_party.get_children()
	
	for i in range(paneles.size()):
		if i < party_jugador.size():
			var heroe = party_jugador[i]
			paneles[i].show()
			paneles[i].find_child("LblNombre").text = heroe.nombre
			paneles[i].find_child("LblPV").text = "PV: " + str(heroe.pv_actuales) + "/" + str(heroe.pv_maximos)
			paneles[i].find_child("LblPH").text = "PH: " + str(heroe.ph_actuales) + "/" + str(heroe.ph_maximos)
		else:
			paneles[i].hide()

# --- SISTEMA DE LOG VISUAL ---
func agregar_al_log(mensaje: String):
	print(mensaje) 
	texto_log.append_text(mensaje + "\n")
