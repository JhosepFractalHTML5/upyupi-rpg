extends Habilidad
class_name TuEscudero

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + " en " + defensor.nombre + "!")
	await bm.get_tree().create_timer(1.0).timeout
	
	# 1. Definimos la duración estándar de un Escudo Humano (2 a 3 turnos)
	var duracion = randi_range(2, 3) 
	
	# 2. Aplicamos la provocación al objetivo elegido
	defensor.aplicar_provocacion(duracion)
	
	# 3. Le subimos 1 nivel de Defensa por la misma cantidad de turnos
	defensor.modificar_stat("defensa", 1, duracion)
	
	# 4. Narrativa de éxito y actualización visual
	bm.ui.narrar("¡" + defensor.nombre + " adopta una postura defensiva y atrae todas las miradas!")
	bm.ui.agregar_al_log("[ESTADO] " + defensor.nombre + " -> Provocación y DEF+ (" + str(duracion) + "T)")
	
	# Forzamos la actualización de la UI para que los íconos de estado aparezcan instantáneamente
	bm.ui.actualizar_interfaz_party(bm.party_jugador)
	
	await bm.get_tree().create_timer(1.5).timeout
	
	# 5. ¡IMPORTANTE! Como esta habilidad NO llama a "recibir_ataque", 
	# tenemos que pasar el turno manualmente al final.
	bm.pasar_turno()
