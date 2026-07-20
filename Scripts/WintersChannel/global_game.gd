extends Node

# --- ESTADO DEL GRUPO ---
# Aquí guardamos los recursos (.tres) de los personajes. 
# Sus inventarios consumibles ya están separados dentro de sus propios recursos~.
var party_actual: Array[CharacterStats] = []

# --- INVENTARIOS COMPARTIDOS (Overworld) ---
# Lo que no se usa en batalla va en la mochila general.
var inventario_equipamiento: Array = []
var inventario_clave: Array = []
var inventario_cartas: Array = []

# --- MEMORIA DEL OVERWORLD ---
var mapa_anterior_ruta: String = ""
var posicion_jugador_mapa: Vector2 = Vector2.ZERO
var volver_de_batalla: bool = false # Sensor para saber si acabamos de pelear

# --- ECONOMÍA ---
var whenes_actuales: int = 0

func _ready():
	# Ufufu... Aquí le damos vida a tu protagonista.
	# ¡Cambia la ruta por la ubicación real de tu recurso de Romn!
	var jhosep = preload("res://BaseDatos/Protagonistas/Jhosep.tres")
	if jhosep:
		party_actual.append(jhosep)
	var romn = preload("res://BaseDatos/Protagonistas/Romn.tres") 
	if romn:
		party_actual.append(romn)
	var massi = preload("res://BaseDatos/Protagonistas/Massi.tres") 
	if massi:
		party_actual.append(massi)
	var thais = preload("res://BaseDatos/Protagonistas/Thais.tres") 
	if thais:
		party_actual.append(thais)

# --- FUNCIONES DE AYUDA GLOBAL ---
func curar_party_completa():
	for heroe in party_actual:
		heroe.pv_actuales = heroe.pv_maximos
		heroe.ph_actuales = heroe.ph_maximos
		heroe.pt_actuales = 0 # Iniciamos el PT vacío para la próxima batalla
		
func agregar_whenes(cantidad: int):
	whenes_actuales += cantidad

# --- PUENTE HACIA LA BATALLA ---
var oleadas_combate_actual: Array = []
var escena_overworld_previa: String = ""

func entrar_a_batalla(oleadas_del_encuentro: Array, ruta_escena_actual: String):
	# Recibimos las oleadas empaquetadas y las guardamos en la memoria global
	oleadas_combate_actual = oleadas_del_encuentro
	escena_overworld_previa = ruta_escena_actual
	
	# ¡CUIDADO! Recuerda usar tu ruta real hacia el gestor de batalla
	get_tree().change_scene_to_file("res://Escenas/Batalla/battle_manager.tscn")

# --- DEGRADACIÓN DE TENSIÓN (PT) EN OVERWORLD ---
var distancia_caminada: float = 0.0
@export var distancia_para_perder_pt: float = 250.0 # Ajusta esto para que drenen más lento o rápido

func registrar_movimiento(distancia_recorrida: float):
	distancia_caminada += distancia_recorrida
	if distancia_caminada >= distancia_para_perder_pt:
		distancia_caminada = 0.0 # Reiniciamos el contador de pasos
		_drenar_pt_party()

func _drenar_pt_party():
	for heroe in party_actual:
		if heroe.pt_actuales > 0:
			heroe.pt_actuales -= 1
