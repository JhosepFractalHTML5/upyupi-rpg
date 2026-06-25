extends Habilidad

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " le grita a " + defensor.nombre + " que hay algo detrás de él!!!")
	await bm.get_tree().create_timer(1.5).timeout
	
	var turnos_distra = randi_range(4, 6)
	defensor.turnos_distraido = turnos_distra
	defensor.turnos_agilidad_baja = 6 
	
	bm.ui.agregar_al_log("[ESTADO] " + defensor.nombre + " -> Distraído")
	bm.ui.narrar(defensor.nombre + " se nota distraído!")
	
	await bm.get_tree().create_timer(1.2).timeout
	bm.pasar_turno()
