extends Resource
class_name Habilidad

@export var nombre: String = ""
@export var costo_ph: int = 0
@export var costo_pt: int = 0 
@export var dano_base: int = 20
@export var es_ataque_atipico: bool = false
@export var es_ataque_fuerte: bool = false # <--- ¡NUEVA CLASIFICACIÓN!
@export_enum("enemigo", "usuario", "aliado", "aleatorio") var objetivo: String = "enemigo"
@export var cooldown: int = 0
@export_multiline var descripcion: String = ""

# El Battle Manager llamará a esto
func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + "!")
	await bm.get_tree().create_timer(0.8).timeout
	
	if es_ataque_atipico: 
		await defensor.recibir_ataque_atipico(atacante, bm)
	else: 
		await defensor.recibir_ataque(atacante, bm)
