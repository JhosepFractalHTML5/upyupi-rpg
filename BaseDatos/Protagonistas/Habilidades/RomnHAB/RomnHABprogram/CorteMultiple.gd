extends Habilidad

func ejecutar(atacante: CharacterStats, _defensor_nulo: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " corta sin piedad al enemigo!!!")
	await bm.get_tree().create_timer(1.0).timeout
	
	for secuencia in range(3):
		var vivos = bm.enemigos_actuales.filter(func(e): return e.pv_actuales > 0)
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
			
			var sprite = bm.sprites_enemigos[defensor]
			sprite.modulate = Color(3, 0.5, 0.5) 
			var tween = bm.get_tree().create_tween()
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
			
			await bm.get_tree().create_timer(0.25).timeout 
			
			var batalla_sigue = await bm.verificar_estado_batalla(defensor, false)
			if not batalla_sigue: return 
	bm.pasar_turno()
