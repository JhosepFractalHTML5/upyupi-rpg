extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor_nulo: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " corta sin piedad al rival!!!")
	await bm.get_tree().create_timer(1.0).timeout
	
	# --- CORRECCIÓN DE BANDO: Detectamos quién es el atacante ---
	var grupo_rival = bm.enemigos_actuales if bm.party_jugador.has(atacante) else bm.party_jugador
	
	for secuencia in range(3):
		var vivos = grupo_rival.filter(func(e): return e.pv_actuales > 0)
		if vivos.is_empty(): break 
		var defensor = vivos.pick_random()
		
		for golpe in range(2):
			if defensor.pv_actuales <= 0: break 
			
			var defensa_real = defensor.defensa
			if defensor.turnos_mejora_defensa > 0: defensa_real = int(defensa_real * 1.5)
			
			var dano_calculado = (atacante.ataque * 4) - defensa_real
			var dano_final = max(1, dano_calculado)
			if defensor.esta_defendiendo: dano_final = int(dano_final * 0.55)
			
			defensor.recibir_dano(dano_final)
			defensor.dano_recibido_esta_ronda += dano_final
			bm.ui.agregar_al_log("[CORTE MÚLTIPLE " + str(secuencia+1) + "/3] " + atacante.nombre + " -> " + defensor.nombre + " (-" + str(dano_final) + " PV)")
			
			# Efecto visual de daño (distinto si es monstruo o héroe)
			if bm.enemigos_actuales.has(defensor):
				var sprite = bm.sprites_enemigos[defensor]
				sprite.modulate = Color(3, 0.5, 0.5) 
				var tween = bm.get_tree().create_tween()
				tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
			else:
				var indice = bm.party_jugador.find(defensor)
				var panel = bm.ui.contenedor_party.get_child(indice)
				panel.modulate = Color(3, 0.5, 0.5)
				var tween = bm.get_tree().create_tween()
				tween.tween_property(panel, "modulate", Color.WHITE, 0.15)
				bm.ui.actualizar_interfaz_party(bm.party_jugador)
			
			await bm.get_tree().create_timer(0.25).timeout 
			
			var batalla_sigue = await bm.verificar_estado_batalla(defensor, false)
			if not batalla_sigue: return 
			
	bm.pasar_turno()
