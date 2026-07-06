extends Resource
class_name Habilidad

@export var icono: Texture2D
@export var fondo_panel: Texture2D
@export var nombre: String = ""
@export var costo_ph: int = 0
@export var costo_pt: int = 0 
@export var dano_base: int = 20
@export var es_ataque_atipico: bool = false
@export var es_ataque_fuerte: bool = false 

# --- ¡NUEVAS CATEGORÍAS DE OBJETIVO! ---
@export_enum("enemigo", "usuario", "aliado", "aleatorio_enemigos", "aleatorio_aliados", "todos_enemigos", "todos_aliados") var objetivo: String = "enemigo"
@export_enum("ofensiva", "tecnica", "curativa") var categoria_ia: String = "ofensiva" 
@export var puede_revivir: bool = false
@export var cooldown: int = 0
@export_multiline var descripcion: String = ""

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + "!")
	await bm.get_tree().create_timer(0.8).timeout
	
	if es_ataque_atipico: 
		await defensor.recibir_ataque_atipico(atacante, bm)
	else: 
		await defensor.recibir_ataque(atacante, bm)
