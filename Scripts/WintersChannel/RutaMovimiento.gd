extends Node
class_name RutaMovimiento

@onready var cuerpo = get_parent() # El personaje al que se lo peguemos (Jhosep, NPC, etc.)
const TAMANO_CASILLA: float = 48.0 # Equivalente a 1 "Tile" para que midas distancias fácil

# ==========================================
# COMANDO 1: MOVER
# ==========================================
func mover(direccion: Vector2, casillas: float, velocidad: float = 100.0):
	# Calculamos cuántos píxeles se va a mover en total
	var distancia_total = casillas * TAMANO_CASILLA
	var pos_destino = cuerpo.global_position + (direccion * distancia_total)
	
	# Usamos el Tween de Godot (el motor de animaciones matemáticas)
	var tween = create_tween()
	var tiempo = distancia_total / velocidad # Tiempo exacto para mantener velocidad constante
	
	# Si el personaje tiene funciones de animación (como tu Jugador), las activamos
	if cuerpo.has_method("_actualizar_animacion"):
		cuerpo._actualizar_animacion(direccion)
		if cuerpo.get("anim_player"):
			cuerpo.anim_player.play(cuerpo.get("anim_actual"))
			
	# Movemos al personaje fluidamente
	tween.tween_property(cuerpo, "global_position", pos_destino, tiempo)
	
	# La magia de RPG Maker: "Esperar hasta finalizar"
	await tween.finished
	
	# Detenemos la animación al llegar
	if cuerpo.get("anim_player"):
		cuerpo.anim_player.stop()

# ==========================================
# COMANDO 2: ESPERAR
# ==========================================
func esperar(segundos: float):
	await get_tree().create_timer(segundos).timeout

# ==========================================
# COMANDO 3: SALTAR (El gag clásico de sorpresa)
# ==========================================
func saltar():
	var tween = create_tween()
	var pos_y_original = cuerpo.global_position.y
	
	# Sube rápido (Ease Out)
	tween.tween_property(cuerpo, "global_position:y", pos_y_original - 24, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Baja rápido (Ease In)
	tween.tween_property(cuerpo, "global_position:y", pos_y_original, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tween.finished
