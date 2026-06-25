extends Habilidad

# Al poner "= null", permitimos que esta función se llame desde el menú de pausa sin un Battle Manager
func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node = null):
	
	# Fórmula: 45% de los PV Máximos del objetivo
	var curacion = int(defensor.pv_maximos * 0.45)
	
	# --- MODO BATALLA ---
	if bm != null:
		bm.ui.narrar("¡" + atacante.nombre + " prepara una hamburguesa rápidamente!!!")
		await bm.get_tree().create_timer(1.0).timeout
		
		# Aplicamos la curación (sin pasarnos del máximo de vida)
		defensor.pv_actuales = min(defensor.pv_actuales + curacion, defensor.pv_maximos)
		
		# Nota: Aquí en el futuro puedes añadir el código para quitar el estado "Hambre" si lo implementas
		# if defensor.estado == "hambre": defensor.estado = "normal"
		
		bm.ui.agregar_al_log("[CURACIÓN] " + atacante.nombre + " -> " + defensor.nombre + " (+" + str(curacion) + " PV)")
		
		# Efecto visual curativo (Parpadeo verde)
		var paneles = bm.ui.contenedor_party.get_children()
		var indice = bm.party_jugador.find(defensor)
		if indice != -1:
			var panel_aliado = paneles[indice]
			panel_aliado.modulate = Color(0.5, 1.0, 0.5) # Color verde esperanza
			var tween = bm.get_tree().create_tween()
			tween.tween_property(panel_aliado, "modulate", Color.WHITE, 0.3)
		
		bm.ui.actualizar_interfaz_party(bm.party_jugador)
		await bm.get_tree().create_timer(0.8).timeout
		
		bm.pasar_turno()
		
	# --- MODO OVERWORLD (Menú de Pausa / Fuera de Batalla) ---
	else:
		# En el overworld no hay narrador ni turnos, solo la pura matemática
		defensor.pv_actuales = min(defensor.pv_actuales + curacion, defensor.pv_maximos)
		print(atacante.nombre + " ha curado a " + defensor.nombre + " por " + str(curacion) + " PV fuera de combate.")
