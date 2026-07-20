extends Resource
class_name CharacterStats

@export_group("Información General")
@export var nombre: String = "Personaje"
@export var clase: String = "Novato"
@export var nivel: int = 1
@export var nivel_maximo: int = 99 

@export_group("Visuales")
@export var textura_sprite: Texture2D
@export var retrato_base: Texture2D
@export var icono_timeline: Texture2D
@export var textura_panel: Texture2D
@export var textura_pose_menu: Texture2D # <-- ¡NUEVO: Para la pose chistosa del Overworld!
@export var color_interfaz: Color = Color.WHITE # <--- NUEVO: Color de sus siglas

@export_group("Salud y Energía")
@export var pv_maximos: int = 100
@export var pv_actuales: int = 100
@export var ph_maximos: int = 50
@export var ph_actuales: int = 50

@export_group("Estadísticas Físicas")
@export var ataque: int = 10
@export var defensa: int = 10
@export var agilidad: int = 15 # Determina quién ataca primero

@export_group("Estadísticas Atípicas")
@export var ataque_atipico: int = 5 
@export var defensa_atipica: int = 5

@export_group("Otros")
@export var suerte: int = 5

@export_group("Atributos Avanzados (%)")
@export var tasa_objetivo: float = 1.0 # 1.0 = 100% (Aggro normal)
@export var tasa_acierto: float = 1.0 # 1.0 = 100% de acierto
@export var tasa_evasion: float = 0.05 # 0.05 = 5% de esquivar
@export var tasa_critico: float = 0.05 # 0.05 = 5% de chance crítica
@export var bono_contraataque: float = 0.03 # 0.03 = 3% extra de growth por golpe
@export var farmacologia: float = 1.0 # 1.0 = 100% de efectividad de items
@export var recuperacion_pt: float = 1.0 # 1.0 = 100% ganancia de PT
@export var tasa_experiencia: float = 1.0 # 1.0 = exp normal

@export_group("Progreso (Jugadores)")
@export var exp_actual: int = 0
@export var exp_necesaria_proximo_nivel: int = 100
@export var puntos_estadisticas: int = 0

@export_group("Items")
@export var max_items: int = 8 # Empezamos en 8, luego lo puedes subir a 16
@export var inventario: Array[ItemConsumible] = []

@export_group("Recompensas (Enemigos)")
@export var drop_experiencia: int = 25
@export var drop_whenes: int = 10 # Cantidad de Whenes que suelta al morir
@export var item_dropeable: ItemConsumible # El recurso del objeto que puede soltar
@export_range(0.0, 100.0) var chance_drop: float = 20.0 # 20% de probabilidad por defecto

@export_group("Inteligencia Artificial")
@export_enum("easy", "normal", "hard") var nivel_ia: String = "normal"

@export_group("Puntos Temperamento (PT)")
@export var pt_maximos: int = 100
@export var pt_actuales: int = 0 # Empezamos el combate con 0 PT

@export_group("Estados de Batalla")
var acumulador_contraataque: float = 0.0 # Guardará la rabia acumulativa por golpes
var turnos_mejora_ataque: int = 0
var turnos_mejora_defensa: int = 0
var turnos_mejora_agilidad: int = 0
var turnos_agilidad_baja: int = 0

@export_group("Sistema de Habilidades")
# Aquí arrastrarás las habilidades que ese personaje PUEDE aprender (máximo 6)
@export var max_habilidades_activas: int = 2
@export var habilidades_disponibles: Array[Habilidad] = []

# Interruptores de prueba que simulan si ya encontraste el ítem clave en el mundo
@export var item_clave_hab_1: bool = false
@export var item_clave_hab_2: bool = false
@export var item_clave_hab_3: bool = false
@export var item_clave_hab_4: bool = false
@export var item_clave_hab_5: bool = false
@export var item_clave_hab_6: bool = false

@export_group("Habilidades Especiales")
@export var habilidad_contraataque: Habilidad # <--- Aquí arrastraremos la habilidad "Alerta"

func gastar_ph(cantidad: int) -> bool:
	if ph_actuales >= cantidad:
		ph_actuales -= cantidad
		print(nombre, " usa una habilidad. PH restantes: ", ph_actuales)
		return true
	else:
		print(nombre, " no tiene suficientes PH.")
		return false

# --- LÓGICA DE CRECIMIENTO ---

func ganar_experiencia(cantidad: int):
	if nivel >= nivel_maximo: return
	exp_actual += int(cantidad * tasa_experiencia)
	while exp_actual >= exp_necesaria_proximo_nivel and nivel < nivel_maximo:
		subir_nivel()

func subir_nivel():
	nivel += 1
	exp_actual -= exp_necesaria_proximo_nivel
	exp_necesaria_proximo_nivel = int(exp_necesaria_proximo_nivel * 1.5) 
	
	# ¡MAGIA! Otorgamos los 3 puntos para invertir
	puntos_estadisticas += 3
	
	pv_actuales = pv_maximos
	ph_actuales = ph_maximos
	
	print("¡NUEVO NIVEL! ", nombre, " alcanzó el nivel ", nivel, ". Puntos disponibles: ", puntos_estadisticas)

var cooldowns_actuales: Dictionary = {} # Guarda la cuenta regresiva de cada magia

# --- IA ENEMIGA MEGA-ACTUALIZADA ---
func ejecutar_ia(bm: Node, party_jugador: Array):
	var heroes_vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
	var aliados_vivos = bm.enemigos_actuales.filter(func(e): return e.pv_actuales > 0)
	
	await bm.get_tree().create_timer(0.8).timeout
	
	if turnos_distraido > 0 and (randi() % 100) < 80:
		bm.ui.narrar("¡" + nombre + " está mirando a otro lado y pierde su turno!")
		bm.pasar_turno()
		return
		
	var chance_random = 25 
	if nivel_ia == "easy": chance_random = 55
	elif nivel_ia == "hard": chance_random = 5
		
	var actuar_random = (randi() % 100) < chance_random
	var habs_usables = []
	for hab in habilidades_disponibles:
		var cd = cooldowns_actuales.get(hab, 0)
		var bloqueado = (turnos_distraido > 0 and hab.es_ataque_fuerte)
		if cd == 0 and ph_actuales >= hab.costo_ph and pt_actuales >= hab.costo_pt and not bloqueado:
			habs_usables.append(hab)

	var accion_elegida = null
	var objetivo_elegido = null
	
	if actuar_random:
		if habs_usables.size() > 0 and randf() > 0.4:
			accion_elegida = habs_usables.pick_random()
		else:
			accion_elegida = "atacar" if randf() > 0.3 else "atipico"
	else:
		var aliado_herido = null
		for a in aliados_vivos:
			if a.pv_actuales < (a.pv_maximos * 0.4):
				aliado_herido = a
				break
				
		var habs_curativas = habs_usables.filter(func(h): return h.categoria_ia == "curativa")
		var habs_tecnicas = habs_usables.filter(func(h): return h.categoria_ia == "tecnica")
		var habs_ofensivas = habs_usables.filter(func(h): return h.categoria_ia == "ofensiva")
		
		if aliado_herido != null and habs_curativas.size() > 0:
			accion_elegida = habs_curativas.pick_random()
			objetivo_elegido = aliado_herido
		elif habs_tecnicas.size() > 0 and randf() > 0.6: 
			accion_elegida = habs_tecnicas.pick_random()
		elif habs_ofensivas.size() > 0:
			accion_elegida = habs_ofensivas.pick_random()
		else:
			accion_elegida = "atacar" if randf() > 0.2 else "atipico"
			
	if objetivo_elegido == null:
		if accion_elegida is Habilidad:
			if accion_elegida.objetivo == "aliado":
				objetivo_elegido = bm.obtener_objetivo_por_aggro(aliados_vivos)
			elif accion_elegida.objetivo == "usuario":
				objetivo_elegido = self
			else:
				objetivo_elegido = _elegir_heroe_inteligente(heroes_vivos, actuar_random, bm)
		else:
			objetivo_elegido = _elegir_heroe_inteligente(heroes_vivos, actuar_random, bm)

	if accion_elegida is Habilidad:
		ph_actuales -= accion_elegida.costo_ph
		pt_actuales -= accion_elegida.costo_pt
		if accion_elegida.cooldown > 0:
			cooldowns_actuales[accion_elegida] = accion_elegida.cooldown
			
		bm.ui.actualizar_interfaz_party(bm.party_jugador)
		await accion_elegida.ejecutar(self, objetivo_elegido, bm)
		bm.ui.actualizar_interfaz_party(bm.party_jugador)
	else:
		bm.ui.narrar("¡" + nombre + " ataca a " + objetivo_elegido.nombre + "!")
		pt_actuales = min(pt_actuales + int(20 * recuperacion_pt), pt_maximos) 
		await bm.get_tree().create_timer(0.8).timeout
		
		if accion_elegida == "atipico": await objetivo_elegido.recibir_ataque_atipico(self, bm)
		else: await objetivo_elegido.recibir_ataque(self, bm)

# --- FUNCION DE APOYO DE LA IA ---
func _elegir_heroe_inteligente(heroes: Array, es_random: bool, bm: Node) -> CharacterStats:
	var provocadores = heroes.filter(func(h): return h.turnos_provocacion > 0)
	if provocadores.size() > 0: return provocadores.pick_random()
	if es_random: return bm.obtener_objetivo_por_aggro(heroes)
	
	var victima = heroes[0]
	for h in heroes:
		if h.pv_actuales < victima.pv_actuales:
			victima = h
	return victima

# =========================================================
# --- SISTEMA DE COMBATE (DAÑO, SUERTE Y EFECTOS) ---
# =========================================================

func recibir_ataque(atacante: CharacterStats, manager: Node):
	# 1. Evasión combinada con Suerte
	var evasion_real = tasa_evasion + (get_suerte_real() * 0.005)
	if turnos_distraido > 0: evasion_real = 0.0 # No esquivas si estás en las nubes
	
	if randf() < evasion_real:
		manager.ui.narrar("¡" + nombre + " esquivó el ataque!")
		manager.ui.agregar_al_log("[ESQUIVE] " + nombre + " esquivó el golpe de " + atacante.nombre)
		manager.mostrar_numero_flotante(self, 0, "evasion")
		await manager.get_tree().create_timer(1.2).timeout
		manager.verificar_estado_batalla(self, true)
		return
		
	# 2. Chance de Crítico
	var critico_real = atacante.tasa_critico + (atacante.get_suerte_real() * 0.01)
	var es_critico = randf() < critico_real
		
	# 3. Cálculo de daño brutal
	var atk_real = atacante.get_ataque_real()
	var def_real = get_defensa_real()
	var dano = int((atk_real * 1.5) - (def_real * 0.5))
	
	# 4. Multiplicadores
	if es_critico: dano = int(dano * 1.5) 
	if esta_defendiendo: dano = int(dano * 0.5) 
	if turnos_distraido > 0: dano = int(dano * 1.25) 
	
	dano = max(1, dano) # El daño nunca puede ser negativo
	pv_actuales = max(pv_actuales - dano, 0)
	var desperto_por_dolor = registrar_dano_ronda(dano)
	var texto_log = "[DAÑO] " + atacante.nombre + " -> " + nombre + " (-" + str(dano) + " PV)"
	
	# 5. Narrativa y Efectos
	if es_critico:
		manager.ui.narrar("¡GOLPE CRÍTICO! " + nombre + " recibe " + str(dano) + " de daño.")
		texto_log = "[CRÍTICO] " + atacante.nombre + " -> " + nombre + " (-" + str(dano) + " PV)"
	else:
		manager.ui.narrar("¡" + nombre + " recibe " + str(dano) + " de daño!")
		
	manager.ui.agregar_al_log(texto_log)
	manager.mostrar_numero_flotante(self, dano, "normal")
	
	if manager.party_jugador.has(self): manager.ui.aplicar_temblor(float(dano) / float(pv_maximos))
	else: manager.animar_parpadeo_enemigo(self)
		
	await manager.get_tree().create_timer(1.0).timeout
	
	if desperto_por_dolor:
		manager.ui.actualizar_interfaz_party(manager.party_jugador) 
		manager.ui.agregar_al_log("[ESTADO] " + nombre + " -/> Distraído (Golpe Masivo)")
		manager.ui.narrar("¡El tremendo golpe despierta a " + nombre + " de su distracción!")
		await manager.get_tree().create_timer(1.2).timeout
		
	# 6. Reacción a la sangre
	var hizo_contraataque = false
	if pv_actuales > 0 and self.has_method("evaluar_contraataque"):
		hizo_contraataque = await evaluar_contraataque(atacante, manager)
		
	if not hizo_contraataque:
		manager.verificar_estado_batalla(self, true)

func recibir_ataque_atipico(atacante: CharacterStats, bm: Node):
	var evasion_real = tasa_evasion + (get_suerte_real() * 0.005)
	if turnos_distraido > 0: evasion_real = 0.0
	
	if randf() < evasion_real:
		bm.ui.narrar("¡" + nombre + " evadió el efecto atípico!")
		bm.ui.agregar_al_log("[ESQUIVE] " + nombre + " evadió la alteración de " + atacante.nombre)
		bm.mostrar_numero_flotante(self, 0, "evasion")
		await bm.get_tree().create_timer(1.2).timeout
		bm.verificar_estado_batalla(self, true)
		return

	var critico_real = atacante.tasa_critico + (atacante.get_suerte_real() * 0.01)
	var es_critico = randf() < critico_real

	var atk_real = atacante.get_ataque_atipico_real()
	var def_real = get_defensa_atipica_real()
	var dano = int((atk_real * 2.5) - (def_real * 1.5))
	
	if es_critico: dano = int(dano * 1.5)
	if esta_defendiendo: dano = int(dano * 0.55)
	if turnos_distraido > 0: dano = int(dano * 1.5)
	
	dano = max(1, dano)
	pv_actuales = max(pv_actuales - dano, 0)
	var desperto_por_dolor = registrar_dano_ronda(dano)
	
	var texto_log = "[ATÍPICO] " + atacante.nombre + " -> " + nombre + " (-" + str(dano) + " PV)"
	if es_critico:
		bm.ui.narrar("¡Mente rota! " + nombre + " recibe " + str(dano) + " de daño atípico.")
		texto_log = "[CRÍTICO ATÍPICO] " + atacante.nombre + " -> " + nombre + " (-" + str(dano) + " PV)"
	else:
		bm.ui.narrar("¡" + nombre + " sufre " + str(dano) + " de daño atípico!")
		
	bm.ui.agregar_al_log(texto_log)
	bm.mostrar_numero_flotante(self, dano, "atipico")
	
	if bm.party_jugador.has(self): bm.ui.aplicar_temblor(float(dano) / float(pv_maximos))
	else: bm.animar_parpadeo_enemigo(self)
	
	await bm.get_tree().create_timer(1.0).timeout
	
	if desperto_por_dolor:
		bm.ui.actualizar_interfaz_party(bm.party_jugador) 
		bm.ui.agregar_al_log("[ESTADO] " + nombre + " -/> Distraído (Choque Mental)")
		bm.ui.narrar("¡El choque mental despierta a " + nombre + " de su distracción!")
		await bm.get_tree().create_timer(1.2).timeout
	
	var hizo_contraataque = await evaluar_contraataque(atacante, bm)
	if not hizo_contraataque: 
		bm.verificar_estado_batalla(self, true)

# --- SISTEMA DE CONTRAATAQUES MODIFICADO ---
func evaluar_contraataque(atacante: CharacterStats, bm: Node) -> bool:
	if bm.party_jugador.has(self) and pv_actuales > 0 and turnos_distraido == 0:
		acumulador_contraataque += bono_contraataque 
		if randf() < acumulador_contraataque:
			acumulador_contraataque = 0.0 
			if habilidad_contraataque != null:
				await habilidad_contraataque.ejecutar(self, atacante, bm)
			else:
				bm.ui.narrar("¡" + nombre + " reacciona con un contraataque!")
				await bm.get_tree().create_timer(1.0).timeout
				await atacante.recibir_ataque(self, bm) 
			return true 
	return false

# =========================================================
# --- SISTEMA DE ESTADOS (BUFFS, DEBUFFS Y ALTERADOS) ---
# =========================================================

# --- 1. STATS BÁSICOS (-2 a +2) ---
var niveles_stat: Dictionary = {
	"ataque": 0, "defensa": 0, "agilidad": 0, "suerte": 0,
	"ataque_atipico": 0, "defensa_atipica": 0 # <-- AGREGADOS para evitar crasheos
}
var turnos_stat: Dictionary = {
	"ataque": 0, "defensa": 0, "agilidad": 0, "suerte": 0,
	"ataque_atipico": 0, "defensa_atipica": 0
}

# --- 2. ESTADOS ESPECIALES ---
var turnos_provocacion: int = 0
var turnos_distraido: int = 0
var esta_defendiendo: bool = false
var dano_recibido_esta_ronda: int = 0

# --- MODIFICADORES DE STATS ---
func modificar_stat(stat: String, niveles_a_sumar: int, turnos: int):
	if niveles_stat.has(stat):
		niveles_stat[stat] = clamp(niveles_stat[stat] + niveles_a_sumar, -2, 2)
		turnos_stat[stat] = turnos 

func get_ataque_real() -> int: return int(ataque * (1.0 + (niveles_stat.get("ataque", 0) * 0.25)))
func get_defensa_real() -> int: return int(defensa * (1.0 + (niveles_stat.get("defensa", 0) * 0.25)))
func get_agilidad_real() -> int: return int(agilidad * (1.0 + (niveles_stat.get("agilidad", 0) * 0.25)))
func get_suerte_real() -> int: return int(suerte * (1.0 + (niveles_stat.get("suerte", 0) * 0.25)))
func get_ataque_atipico_real() -> int: return int(ataque_atipico * (1.0 + (niveles_stat.get("ataque_atipico", 0) * 0.25)))
func get_defensa_atipica_real() -> int: return int(defensa_atipica * (1.0 + (niveles_stat.get("defensa_atipica", 0) * 0.25)))

# --- MODIFICADORES DE ESTADOS ESPECIALES ---
func aplicar_provocacion(turnos: int): turnos_provocacion = turnos
func aplicar_distraccion(turnos: int): turnos_distraido = turnos
func activar_defensa(): esta_defendiendo = true

# --- PROCESAR EL PASO DEL TIEMPO ---
# Se llama al inicio del turno. Devuelve un Array con los estados que expiraron
# para que el Manager pueda narrarlos en pantalla.
func procesar_turnos_estados() -> Array:
	var expirados = []
	
	# Restar turnos a los Buffs/Debuffs
	for stat in turnos_stat.keys():
		if turnos_stat[stat] > 0:
			turnos_stat[stat] -= 1
			if turnos_stat[stat] == 0:
				niveles_stat[stat] = 0 
	
	# Restar turnos a Provocación
	if turnos_provocacion > 0:
		turnos_provocacion -= 1
		if turnos_provocacion == 0: expirados.append("PROVOCACION")
			
	# Restar turnos a Distracción
	if turnos_distraido > 0:
		turnos_distraido -= 1
		if turnos_distraido == 0: expirados.append("DISTRACCION")
			
	# La defensa solo dura hasta que el personaje vuelve a actuar
	if esta_defendiendo:
		esta_defendiendo = false
		
	return expirados

# --- GESTIÓN DE DESPERTAR POR DAÑO ---
func registrar_dano_ronda(dano: int) -> bool:
	dano_recibido_esta_ronda += dano
	# Si está distraído y el daño acumulado supera el 25% de su vida, despierta
	if turnos_distraido > 0 and dano_recibido_esta_ronda >= (pv_maximos * 0.25):
		turnos_distraido = 0
		return true # Avisa al manager que se despertó a la fuerza
	return false

func reiniciar_dano_ronda():
	dano_recibido_esta_ronda = 0
