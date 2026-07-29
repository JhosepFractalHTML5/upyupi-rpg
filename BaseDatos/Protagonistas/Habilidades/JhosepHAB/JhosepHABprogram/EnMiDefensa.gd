extends Habilidad
class_name EnMiDefensa

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + " y embiste con su armadura!")
	
	# Opcional: Pequeña pausa para que se lea el texto
	await bm.get_tree().create_timer(0.8).timeout
	
	# ¡LA MAGIA! Llamamos al ataque normal, pero le pasamos nuestra palabra clave
	await defensor.recibir_ataque(atacante, bm, "en_mi_defensa")
