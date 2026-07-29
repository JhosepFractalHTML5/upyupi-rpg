extends Habilidad
class_name MagiaAtipica

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " desata una anomalía inestable con " + nombre + "!")
	
	await bm.get_tree().create_timer(1.2).timeout
	
	# Lanzamos el ataque con la nueva palabra clave
	await defensor.recibir_ataque(atacante, bm, "magia_atipica")
