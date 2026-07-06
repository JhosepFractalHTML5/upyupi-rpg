extends Habilidad

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " le grita a " + defensor.nombre + " que hay algo detrás de él!!!")
	await bm.get_tree().create_timer(1.5).timeout
	
	var turnos_distra = randi_range(4, 6)
	
	# --- NUEVO: Aplicar debuffos y estados por el canal correcto ---
	defensor.aplicar_distraccion(turnos_distra)
	defensor.modificar_stat("agilidad", -1, 6) # -1 Nivel de Agilidad
	
	bm.ui.agregar_al_log("[ESTADO] " + defensor.nombre + " -> Distraído (AGI-)")
	bm.ui.narrar("¡" + defensor.nombre + " se nota distraído y más lento!")
	
	await bm.get_tree().create_timer(1.2).timeout
	bm.pasar_turno()
