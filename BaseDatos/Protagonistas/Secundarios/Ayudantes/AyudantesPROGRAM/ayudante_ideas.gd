extends Ayudante
class_name AyudanteIdeas

func ejecutar_asistencia(bm: Node):
	var rng = randf() # Genera un número entre 0.0 y 1.0
	
	if rng < 0.80:
		# 80% de probabilidad: No hace nada. Salimos en silencio~
		return
		
	bm.ui.narrar("¡" + nombre + " revolotea por el campo de batalla!")
	await bm.get_tree().create_timer(1.0).timeout
	
	if rng < 0.98:
		# 18% de probabilidad: Dar suerte
		var aliados_validos = bm.party_jugador.filter(func(h): return h.pv_actuales > 0 and h.niveles_stat["suerte"] <= 0)
		if aliados_validos.size() > 0:
			var objetivo = aliados_validos.pick_random()
			objetivo.modificar_stat("suerte", 1, 3) # +1 Nivel de Suerte por 3 turnos
			bm.ui.agregar_al_log("[AYUDANTE] " + nombre + " iluminó a " + objetivo.nombre)
			bm.ui.narrar("¡La luz de " + nombre + " inspira a " + objetivo.nombre + "!")
			bm.ui.actualizar_interfaz_party(bm.party_jugador)
	else:
		# 2% de probabilidad: Distraer a un enemigo
		var enemigos_validos = bm.enemigos_actuales.filter(func(e): return e.pv_actuales > 0 and e.turnos_distraido == 0)
		if enemigos_validos.size() > 0:
			var objetivo = enemigos_validos.pick_random()
			objetivo.aplicar_distraccion(2) # Distraído por 2 turnos
			bm.ui.agregar_al_log("[AYUDANTE] " + nombre + " cegó a " + objetivo.nombre)
			bm.ui.narrar("¡La brillante luz distrae a " + objetivo.nombre + "!")
			
	await bm.get_tree().create_timer(1.2).timeout
