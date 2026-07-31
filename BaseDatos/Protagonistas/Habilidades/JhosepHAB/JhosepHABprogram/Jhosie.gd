extends Habilidad
class_name Jhosie

func ejecutar(atacante: CharacterStats, defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " se pone un vestido e intenta seducir a " + defensor.nombre + "!")
	await bm.get_tree().create_timer(1.8).timeout
	
	# 1. Aplicamos el Enamoramiento al enemigo (¡5 turnos fijos como pediste!)
	var duracion_enamorado = 5
	defensor.aplicar_enamoramiento(duracion_enamorado)
	
	# Narrativa del éxito en el enemigo
	bm.ui.narrar("¡" + defensor.nombre + " queda completamente flechado y embrujado!")
	bm.ui.agregar_al_log("[ESTADO] " + defensor.nombre + " -> Enamorado (5T)")
	bm.ui.actualizar_interfaz_party(bm.party_jugador)
	
	await bm.get_tree().create_timer(1.5).timeout
	
	# 2. El contragolpe moral (Jhosep se avergüenza)
	bm.ui.narrar("¡Pero la vergüenza destruye la moral de " + atacante.nombre + "!")
	
	# Usamos la nueva función para bajar TODOS los stats 1 nivel por 3 turnos (o los que quieras)
	# Nota: Le pondremos la misma duración del embrujo (5 turnos) para que sufra lo mismo que dura el efecto.
	atacante.deprimir_todas_estadisticas(1, duracion_enamorado)
	
	bm.ui.agregar_al_log("[ESTADO] " + atacante.nombre + " -> ¡TODOS LOS STATS BAJARON!")
	bm.ui.actualizar_interfaz_party(bm.party_jugador)
	
	await bm.get_tree().create_timer(1.8).timeout
	
	# 3. ¡MUY IMPORTANTE! Como esta habilidad no hace daño directo (no llama a recibir_ataque),
	# tenemos que forzar el pase de turno manualmente al final.
	bm.pasar_turno()
