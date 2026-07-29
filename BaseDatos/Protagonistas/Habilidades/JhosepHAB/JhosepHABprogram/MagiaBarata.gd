extends Habilidad
class_name MagiaBarata

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " concentra toda su energía mágica restante!")
	
	await bm.get_tree().create_timer(1.2).timeout
	
	# Invocamos el ataque pasando la palabra clave "magia_barata"
	await defensor.recibir_ataque(atacante, bm, "magia_barata")
