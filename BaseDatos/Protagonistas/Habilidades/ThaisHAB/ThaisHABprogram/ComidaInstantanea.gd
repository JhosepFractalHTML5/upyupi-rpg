extends Habilidad

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node = null):
	if defensor.pv_actuales <= 0 and not puede_revivir:
		if bm != null:
			bm.ui.narrar("¡" + defensor.nombre + " está inconsciente! ¡La curación no hace efecto!")
			await bm.get_tree().create_timer(1.5).timeout
			bm.pasar_turno()
		else:
			print("No puedes curar a un aliado caído con esto.")
		return 
		
	# --- NUEVO: Se aplica la Farmacología del defensor ---
	var curacion = int((defensor.pv_maximos * 0.45) * defensor.farmacologia)
	
	if bm != null:
		bm.ui.narrar("¡" + atacante.nombre + " prepara una hamburguesa rápidamente!!!")
		await bm.get_tree().create_timer(1.0).timeout
		
		defensor.pv_actuales = min(defensor.pv_actuales + curacion, defensor.pv_maximos)
		bm.ui.agregar_al_log("[CURACIÓN] " + atacante.nombre + " -> " + defensor.nombre + " (+" + str(curacion) + " PV)")
		
		bm.mostrar_numero_flotante(defensor, curacion, "cura")
		
		# --- NUEVO: Efecto visual compatible con Aliados y Enemigos ---
		if bm.party_jugador.has(defensor):
			var indice = bm.party_jugador.find(defensor)
			var panel_aliado = bm.ui.contenedor_party.get_child(indice)
			panel_aliado.modulate = Color(0.5, 1.0, 0.5) 
			var tween = bm.get_tree().create_tween()
			tween.tween_property(panel_aliado, "modulate", Color.WHITE, 0.3)
		elif bm.sprites_enemigos.has(defensor):
			var sprite = bm.sprites_enemigos[defensor]
			sprite.modulate = Color(0.5, 1.0, 0.5) 
			var tween = bm.get_tree().create_tween()
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
		
		bm.ui.actualizar_interfaz_party(bm.party_jugador)
		await bm.get_tree().create_timer(0.8).timeout
		
		bm.pasar_turno()
	else:
		defensor.pv_actuales = min(defensor.pv_actuales + curacion, defensor.pv_maximos)
		print(atacante.nombre + " ha curado a " + defensor.nombre + " por " + str(curacion) + " PV fuera de combate.")
