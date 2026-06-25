extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor_nulo: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + "!")
	await bm.get_tree().create_timer(1.0).timeout
	
	if randf() > 0.10: 
		var duracion = randi_range(2, 3) 
		atacante.turnos_provocacion = duracion 
		atacante.turnos_mejora_defensa = duracion 
		bm.ui.narrar(atacante.nombre + " es ahora el centro de golpes por " + str(duracion) + " turnos!!!")
		bm.ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -> Escudo Humano")
	else:
		bm.ui.narrar("¡Pero falló!")
		bm.ui.agregar_al_log("[SISTEMA] " + atacante.nombre + " falló Escudo Humano.")
		
	await bm.get_tree().create_timer(1.5).timeout
	bm.pasar_turno()
