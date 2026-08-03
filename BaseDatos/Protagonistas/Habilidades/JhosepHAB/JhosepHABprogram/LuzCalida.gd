extends Habilidad
class_name HabilidadLuzCalida

func _init():
	nombre = "Luz Cálida"
	objetivo = "todos_aliados" 
	categoria_ia = "curativa"
	es_ataque_atipico = false

func ejecutar(atacante: CharacterStats, _defensor: CharacterStats, bm: Node):
	bm.ui.narrar("¡" + atacante.nombre + " invoca una Luz Cálida!")
	await bm.get_tree().create_timer(1.2).timeout
	
	# 1. VERIFICAR SINERGIA CON IDEAS
	if not (bm.ayudante_actual != null and bm.ayudante_actual is AyudanteIdeas):
		bm.ui.narrar("Sin la resonancia de IDEAS, la luz se desvanece rápidamente...")
		await bm.get_tree().create_timer(1.5).timeout
		bm.pasar_turno()
		return
		
	bm.ui.narrar("¡IDEAS canaliza la luz y la expande por el campo!")
	await bm.get_tree().create_timer(1.2).timeout
	
	# 2. LOCALIZAR A JHOSEP EN LA FORMACIÓN
	var indice_jhosep = -1
	
	for i in range(bm.party_jugador.size()):
		var heroe = bm.party_jugador[i]
		if heroe.nombre.to_lower() == "jhosep" and heroe.pv_actuales > 0:
			indice_jhosep = i
			break
			
	if indice_jhosep == -1:
		bm.ui.narrar("¡La luz busca a Jhosep, pero no logra encontrarlo!")
		await bm.get_tree().create_timer(1.5).timeout
		bm.pasar_turno()
		return
		
	# 3. CLASIFICAR ALIADOS (¡Ahora salvamos a Massi!)
	var jhosep_obj = bm.party_jugador[indice_jhosep]
	var costados: Array = []
	var lejanos: Array = []
	
	for i in range(bm.party_jugador.size()):
		var heroe = bm.party_jugador[i]
		if i != indice_jhosep and heroe.pv_actuales > 0:
			var dist = abs(i - indice_jhosep)
			
			if dist == 1:
				costados.append(heroe) # Aliados inmediatamente a los lados (30%)
			else:
				lejanos.append(heroe) # TODOS los demás a distancia 2, 3, etc. (25%)
				
	# 4. APLICAR CURACIONES Y FEEDBACK VISUAL
	bm.ui.narrar("¡La brillante calidez abraza la formación!")
	
	# Función auxiliar para curar y mostrar el número flotante verde
	var aplicar_cura = func(objetivo: CharacterStats, porcentaje: float):
		var sanacion = int(objetivo.pv_maximos * porcentaje)
		objetivo.pv_actuales = min(objetivo.pv_actuales + sanacion, objetivo.pv_maximos)
		bm.mostrar_numero_flotante(objetivo, sanacion, "cura")
		bm.ui.agregar_al_log("[LUZ CÁLIDA] " + objetivo.nombre + " recupera " + str(sanacion) + " PV.")
	
	# A) Curamos al centro del rayo (Jhosep: 50%)
	aplicar_cura.call(jhosep_obj, 0.50)
	
	# B) Curamos a los costados (30%)
	for aliado in costados:
		aplicar_cura.call(aliado, 0.30)
		
	# C) Curamos a los lejanos/resto (25%)
	for aliado in lejanos:
		aplicar_cura.call(aliado, 0.25)
		
	# Actualizamos la interfaz para que las barras de vida suban visualmente
	bm.ui.actualizar_interfaz_party(bm.party_jugador)
	
	await bm.get_tree().create_timer(1.5).timeout
	
	# Fin del turno
	bm.pasar_turno()
