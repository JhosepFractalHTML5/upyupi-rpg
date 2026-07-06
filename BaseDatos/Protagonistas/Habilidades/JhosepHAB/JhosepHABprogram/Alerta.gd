extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor: CharacterStats, bm: Node = null):
	if bm != null:
		bm.ui.narrar(atacante.nombre + " empieza a tener un ataque de pánico.")
		await bm.get_tree().create_timer(1.5).timeout
		
		bm.ui.narrar("¡Pero se calma y enfoca, haciéndose más fuerte!")
		await bm.get_tree().create_timer(1.5).timeout
		
		# --- NUEVO: Se aplica la Farmacología ---
		var curacion = max(1, int((atacante.pv_maximos * 0.02) * atacante.farmacologia))
		atacante.pv_actuales = min(atacante.pv_actuales + curacion, atacante.pv_maximos)
		bm.mostrar_numero_flotante(atacante, curacion, "cura")
		
		# --- NUEVO: Modificar Stats reales ---
		atacante.modificar_stat("ataque", 1, 5)
		atacante.modificar_stat("defensa", 1, 5)
		atacante.modificar_stat("agilidad", 1, 5)
		
		bm.ui.agregar_al_log("[ALERTA] " + atacante.nombre + " se recupera y aumenta todos sus stats.")
		
		# --- NUEVO: Efecto visual compatible con Aliados y Enemigos ---
		if bm.party_jugador.has(atacante):
			var indice = bm.party_jugador.find(atacante)
			var panel_aliado = bm.ui.contenedor_party.get_child(indice)
			panel_aliado.modulate = Color(0.5, 1.0, 0.5) 
			var tween = bm.get_tree().create_tween()
			tween.tween_property(panel_aliado, "modulate", Color.WHITE, 0.3)
		elif bm.sprites_enemigos.has(atacante):
			var sprite = bm.sprites_enemigos[atacante]
			sprite.modulate = Color(0.5, 1.0, 0.5) 
			var tween = bm.get_tree().create_tween()
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
		
		bm.ui.actualizar_interfaz_party(bm.party_jugador)
		await bm.get_tree().create_timer(1.0).timeout
		
		# Pasamos "true" si queremos que acabe su turno, o "false" si se activó como un contraataque de reacción rápida
		await bm.verificar_estado_batalla(atacante, true)
