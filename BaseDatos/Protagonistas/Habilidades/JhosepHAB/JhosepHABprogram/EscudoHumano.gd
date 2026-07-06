extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor_nulo: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + "!")
	await bm.get_tree().create_timer(1.0).timeout
	
	if randf() > 0.10: 
		var duracion = randi_range(2, 3) 
		
		# --- NUEVO: Usamos las funciones de estados que gestiona el Cerebro ---
		atacante.aplicar_provocacion(duracion)
		atacante.modificar_stat("defensa", 1, duracion) # +1 Nivel de Defensa
		
		bm.ui.narrar(atacante.nombre + " es ahora el centro de golpes por " + str(duracion) + " turnos!!!")
		bm.ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -> Escudo Humano (DEF+)")
	else:
		bm.ui.narrar("¡Pero falló!")
		bm.ui.agregar_al_log("[SISTEMA] " + atacante.nombre + " falló Escudo Humano.")
		
	await bm.get_tree().create_timer(1.5).timeout
	bm.pasar_turno()
