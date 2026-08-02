extends Habilidad
class_name HabilidadYaces

func ejecutar(atacante: CharacterStats, _defensor: CharacterStats, bm: Node):
	# 1. Narrativa inicial
	bm.ui.narrar("¡" + atacante.nombre + " usa Yaces contra todos los enemigos!")
	await bm.get_tree().create_timer(0.6).timeout
	
	var ataque_real = atacante.get_ataque_real()
	
	# Obtenemos a todos los enemigos que están vivos actualmente en pantalla
	var enemigos_vivos = bm.enemigos_actuales.filter(func(e): return is_instance_valid(e) and e.pv_actuales > 0)
	
	# 2. BUCLE: Iteramos sobre cada uno de los enemigos para dañarlos
	for enemigo in enemigos_vivos:
		var defensa_real = enemigo.get_defensa_real()
		
		# Fórmula oficial: ⌊(AtaqueReal × 1.5) − (DefensaReal × 0.5)⌋
		var dano_base = int((ataque_real * 1.5) - (defensa_real * 0.5))
		
		# Lo dividimos entre 2 y el mínimo siempre es 1
		var dano_final = max(1, int(dano_base / 2.0))
		
		# Aplicamos el daño manual
		enemigo.pv_actuales -= dano_final
		enemigo.pv_actuales = max(0, enemigo.pv_actuales)
		
		# Feedback visual en pantalla
		bm.mostrar_numero_flotante(enemigo, dano_final, "normal") 
		bm.animar_parpadeo_enemigo(enemigo)
		bm.ui.agregar_al_log("[YACES] " + atacante.nombre + " -> " + enemigo.nombre + " (-" + str(dano_final) + " PV)")
		
		# 3. REDUCCIÓN DE AGILIDAD
		# Usamos tu función interna para que sea limpio: Le bajamos 1 nivel por 3 turnos.
		# (Esta función automáticamente evita que baje de -2)
		enemigo.modificar_stat("agilidad", -1, 3)
		
	# Esperamos un poco a que todos parpadeen y reciban el daño
	await bm.get_tree().create_timer(1.0).timeout
	
	bm.ui.narrar("¡Todos los enemigos han quedado mermados y lentos!")
	await bm.get_tree().create_timer(1.2).timeout
	
	# 4. VERIFICACIÓN DE MUERTES
	# Como hicimos el daño manual a varios, tenemos que chequear quién sobrevivió
	var batalla_sigue = true
	for enemigo in enemigos_vivos:
		if is_instance_valid(enemigo) and enemigo.pv_actuales <= 0:
			# Pasamos 'false' al final para que el manager no avance el turno automáticamente por cada muerto
			batalla_sigue = await bm.verificar_estado_batalla(enemigo, false)
			if not batalla_sigue:
				return # Si la batalla terminó (mataste a todos), salimos de la función
				
	# 5. PASE DE TURNO MANUAL
	bm.pasar_turno()
