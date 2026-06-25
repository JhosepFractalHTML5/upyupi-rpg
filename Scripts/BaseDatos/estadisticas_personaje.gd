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

@export_group("Progreso (Jugadores)")
@export var exp_actual: int = 0
@export var exp_necesaria_proximo_nivel: int = 100

@export_group("Recompensas (Enemigos)")
@export var drop_experiencia: int = 25
@export var drop_whenes: int = 10 # Cantidad de Whenes que suelta al morir

@export_group("Puntos Temperamento (PT)")
@export var pt_maximos: int = 100
var pt_actuales: int = 0 # Empezamos el combate con 0 PT

@export_group("Estados Alterados de Combate")
var turnos_provocacion: int = 0
var turnos_mejora_defensa: int = 0
var turnos_distraido: int = 0
var turnos_agilidad_baja: int = 0
var turnos_mejora_ataque: int = 0
var turnos_mejora_agilidad: int = 0
var dano_recibido_esta_ronda: int = 0

@export_group("Estados de Batalla")
var esta_defendiendo: bool = false
var chance_contraataque: float = 0.0 # Guardará ese 1.5% acumulativo

@export_group("Sistema de Habilidades")
# Aquí arrastrarás las habilidades que ese personaje PUEDE aprender (máximo 6)
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

# --- LÓGICA DE COMBATE Y SUPERVIVENCIA ---

func recibir_dano(cantidad: int):
	pv_actuales -= cantidad
	# Evitamos que la vida baje de 0
	if pv_actuales < 0:
		pv_actuales = 0
	print(nombre, " recibe ", cantidad, " de daño. PV restantes: ", pv_actuales)
	
	if pv_actuales == 0:
		print(nombre, " ha sido derrotado.")

func curar_pv(cantidad: int):
	pv_actuales += cantidad
	# Evitamos curar más allá del máximo
	if pv_actuales > pv_maximos:
		pv_actuales = pv_maximos
	print(nombre, " se cura ", cantidad, " PV. PV actuales: ", pv_actuales)

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
	if nivel >= nivel_maximo:
		return
		
	exp_actual += cantidad
	while exp_actual >= exp_necesaria_proximo_nivel and nivel < nivel_maximo:
		subir_nivel()

func subir_nivel():
	nivel += 1
	exp_actual -= exp_necesaria_proximo_nivel
	exp_necesaria_proximo_nivel = int(exp_necesaria_proximo_nivel * 1.5) 
	
	# Al subir de nivel, normalmente se curan al máximo
	pv_actuales = pv_maximos
	ph_actuales = ph_maximos
	
	print("¡NUEVO NIVEL! ", nombre, " ha alcanzado el nivel ", nivel)

# (Al final de estadisticas_personaje.gd)
var cooldowns_actuales: Dictionary = {} # Guarda la cuenta regresiva de cada magia

# --- IA ENEMIGA ---
func ejecutar_ia(bm: Node, party_jugador: Array):
	# Filtrar posibles objetivos
	var vivos = party_jugador.filter(func(h): return h.pv_actuales > 0)
	var provocadores = vivos.filter(func(h): return h.turnos_provocacion > 0)
	var defensor = provocadores.pick_random() if provocadores.size() > 0 else vivos.pick_random()
	
	var probabilidad = randi() % 100 
	await bm.get_tree().create_timer(0.8).timeout
	
	if turnos_distraido > 0 and probabilidad >= 60 and probabilidad < 90: probabilidad = 95 
	
	if probabilidad < 60:
		bm.ui.narrar("¡" + nombre + " ataca a " + defensor.nombre + "!")
		await bm.get_tree().create_timer(0.8).timeout
		await defensor.recibir_ataque(self, bm)
	elif probabilidad < 90:
		bm.ui.narrar("¡" + nombre + " usa un ataque especial!")
		await bm.get_tree().create_timer(0.8).timeout
		await defensor.recibir_ataque_atipico(self, bm)
	else:
		bm.ui.narrar("¡" + nombre + (" está mirando a otro lado y pierde su turno!" if turnos_distraido > 0 else " tropezó y falló!"))
		bm.pasar_turno()

# --- FÓRMULAS DE DAÑO Y DEFENSA ---
func recibir_ataque(atacante: Resource, bm: Node):
	# ¡NUEVO! Comprobamos si el atacante tiene la mejora de ataque activa (1.5x)
	var ataque_base = atacante.ataque
	if atacante.turnos_mejora_ataque > 0: ataque_base = int(ataque_base * 1.5)
		
	var ataque_real = int(ataque_base * 0.8) if atacante.turnos_distraido > 0 else ataque_base
	var defensa_real = int(defensa * 1.5) if turnos_mejora_defensa > 0 else defensa
	
	var dano_calculado = (ataque_real * 4) - (defensa_real * 2)
	var dano_final = int(max(1, dano_calculado) * 0.55) if esta_defendiendo else max(1, dano_calculado)
	
	recibir_dano(dano_final) 
	dano_recibido_esta_ronda += dano_final
	bm.ui.agregar_al_log("[DAÑO] " + atacante.nombre + " -> " + nombre + " (-" + str(dano_final) + " PV)")
	
	await evaluar_contraataque(atacante, bm)

func recibir_ataque_atipico(atacante: Resource, bm: Node):
	var defensa_real = int(defensa_atipica * 1.5) if turnos_mejora_defensa > 0 else defensa_atipica
	var dano_calculado = (atacante.ataque_atipico * 4) - (defensa_real * 2)
	var dano_final = int(max(1, dano_calculado) * 0.55) if esta_defendiendo else max(1, dano_calculado)
	
	recibir_dano(dano_final)
	dano_recibido_esta_ronda += dano_final 
	bm.ui.agregar_al_log("[DAÑO ATÍPICO] " + atacante.nombre + " -> " + nombre + " (-" + str(dano_final) + " PV)")
	
	await evaluar_contraataque(atacante, bm)

# --- SISTEMA DE CONTRAATAQUES MODIFICADO ---
func evaluar_contraataque(atacante: Resource, bm: Node):
	if bm.party_jugador.has(self) and pv_actuales > 0 and turnos_distraido == 0:
		chance_contraataque += 0.01
		if (randf() * 100.0) < chance_contraataque:
			chance_contraataque = 0.0 
			
			# ¡NUEVO! Si el personaje tiene un contraataque único, lo ejecuta.
			if habilidad_contraataque != null:
				await habilidad_contraataque.ejecutar(self, atacante, bm)
				return # El script de la habilidad se encarga de continuar la batalla
			else:
				# Contraataque físico básico por defecto (para quien no tenga uno único aún)
				bm.ui.narrar("¡" + nombre + " reacciona con un contraataque!")
				await bm.get_tree().create_timer(1.0).timeout
				await atacante.recibir_ataque(self, bm) 
				return 
				
	await bm.verificar_estado_batalla(self)
