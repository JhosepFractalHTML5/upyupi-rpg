extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor_nulo: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " usa " + nombre + "!")
	await bm.get_tree().create_timer(1.0).timeout
	
	if randf() > 0.10: 
		var duracion = randi_range(2, 3) 
		
		# 1. Cubrimos todos los ataques atrayendo el aggro (como Escudo Humano)
		atacante.aplicar_provocacion(duracion)
		
		# 2. Inyectamos la Voluntad Humana SIN subir defensa todavía
		if atacante.has_method("aplicar_voluntad_humana"):
			atacante.aplicar_voluntad_humana(duracion)
		
		bm.ui.narrar("¡" + atacante.nombre + " desata su voluntad por " + str(duracion) + " turnos!")
		bm.ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -> Voluntad Humana (Inmortalidad)")
	else:
		bm.ui.narrar("¡Pero su voluntad flaqueó!")
		bm.ui.agregar_al_log("[SISTEMA] " + atacante.nombre + " falló Voluntad Humana.")
		
	await bm.get_tree().create_timer(1.5).timeout
	bm.pasar_turno()
