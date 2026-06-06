extends Resource
class_name CharacterStats

@export_group("Información General")
@export var nombre: String = "Personaje"
@export var clase: String = "Novato"
@export var nivel: int = 1
@export var nivel_maximo: int = 99 

@export_group("Visuales")
@export var textura_sprite: Texture2D

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

@export_group("Estados de Batalla")
var esta_defendiendo: bool = false
var chance_contraataque: float = 0.0 # Guardará ese 1.5% acumulativo

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
