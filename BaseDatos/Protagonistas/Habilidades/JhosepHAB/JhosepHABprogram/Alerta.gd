extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor: CharacterStats, bm: Node = null):
	if bm != null:
		# 1. Narrativa del ataque de pánico
		bm.ui.narrar(atacante.nombre + " empieza a tener un ataque de pánico.")
		await bm.get_tree().create_timer(1.5).timeout
		
		bm.ui.narrar("pero se calma y enfoca, haciendose más fuerte")
		await bm.get_tree().create_timer(1.5).timeout
		
		# 2. Curación del 2%
		var curacion = max(1, int(atacante.pv_maximos * 0.02)) # Aseguramos curar al menos 1 PV
		atacante.pv_actuales = min(atacante.pv_actuales + curacion, atacante.pv_maximos)
		
		# 3. Añadir las ventajas de 5 turnos (Multiplicadores de stats)
		atacante.turnos_mejora_ataque = 5
		atacante.turnos_mejora_defensa = 5
		atacante.turnos_mejora_agilidad = 5
		
		bm.ui.agregar_al_log("[ALERTA] " + atacante.nombre + " se recupera y aumenta todos sus stats.")
		
		# 4. Efecto visual verde de curación en su panel
		var paneles = bm.ui.contenedor_party.get_children()
		var indice = bm.party_jugador.find(atacante)
		if indice != -1:
			var panel_aliado = paneles[indice]
			panel_aliado.modulate = Color(0.5, 1.0, 0.5) 
			var tween = bm.get_tree().create_tween()
			tween.tween_property(panel_aliado, "modulate", Color.WHITE, 0.3)
		
		bm.ui.actualizar_interfaz_party(bm.party_jugador)
		await bm.get_tree().create_timer(1.0).timeout
		
		# 5. MUY IMPORTANTE: Retornamos el flujo de la batalla para que pase el turno a la siguiente persona
		await bm.verificar_estado_batalla(atacante)
