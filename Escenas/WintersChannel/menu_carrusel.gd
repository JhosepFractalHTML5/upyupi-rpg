extends Control

# --- REFERENCIAS INTERNAS ---
@onready var retrato_carrusel = $HBoxCarrusel/ZonaIzquierda/RetratoCarrusel
@onready var lbl_nombre_carrusel = $HBoxCarrusel/ZonaIzquierda/LblNombreCarrusel
@onready var lbl_conteo_carrusel = $HBoxCarrusel/ZonaIzquierda/LblConteoCartas
@onready var pista_movimiento = $HBoxCarrusel/ZonaCartas/PistaMovimiento

# --- MEMORIA DEL CARRUSEL ---
var cartas_agrupadas: Dictionary = {}
var carrusel_personajes_base: Array = [] 
var filas_infinitas: Array = [] 
var indice_carrusel_y: int = 0 
var indices_carrusel_x: Dictionary = {} 

# --- DISTANCIAS ---
const ESPACIO_Y = 220 
const ESPACIO_X = 170 
const CENTRO_PANTALLA_Y = 340 
const CENTRO_PANTALLA_X = 60  

func _input(event):
	# Si el carrusel no está visible, ignoramos los inputs
	if not visible or carrusel_personajes_base.is_empty(): return
	
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_verificar_bucle_infinito()
		indice_carrusel_y -= 1
		_verificar_bucle_infinito()
		_actualizar_carrusel_visual()
			
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_verificar_bucle_infinito()
		indice_carrusel_y += 1
		_verificar_bucle_infinito()
		_actualizar_carrusel_visual()
			
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		var pj_actual = filas_infinitas[indice_carrusel_y] 
		if indices_carrusel_x[pj_actual] > 0:
			indices_carrusel_x[pj_actual] -= 1
			_actualizar_carrusel_visual()
			
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		var pj_actual = filas_infinitas[indice_carrusel_y]
		if indices_carrusel_x[pj_actual] < 5: 
			indices_carrusel_x[pj_actual] += 1
			_actualizar_carrusel_visual()

func _verificar_bucle_infinito():
	var tam = carrusel_personajes_base.size()
	var teletransportado = false
	
	if indice_carrusel_y <= tam * 2:
		indice_carrusel_y += tam * 4
		teletransportado = true
	elif indice_carrusel_y >= tam * 7:
		indice_carrusel_y -= tam * 4
		teletransportado = true
		
	if teletransportado:
		_actualizar_carrusel_visual(true)

func abrir(inventario_global: Array):
	# 1. Agrupamos las cartas de forma aislada
	cartas_agrupadas.clear()
	for carta in inventario_global:
		if carta == null: continue
		var dueño = carta.personaje_coleccion
		if not cartas_agrupadas.has(dueño):
			cartas_agrupadas[dueño] = []
		cartas_agrupadas[dueño].append(carta)
		
	# 2. Reiniciamos el bucle
	carrusel_personajes_base = ["Jhosep", "Romn", "Massi", "Thais"]
	
	for pj in carrusel_personajes_base:
		if not cartas_agrupadas.has(pj):
			cartas_agrupadas[pj] = []
			
	for hijo in pista_movimiento.get_children():
		pista_movimiento.remove_child(hijo)
		hijo.queue_free()
		
	indices_carrusel_x.clear()
	filas_infinitas.clear()
	
	for pj in carrusel_personajes_base:
		indices_carrusel_x[pj] = 0
		
	for i in range(9):
		filas_infinitas.append_array(carrusel_personajes_base)
		
	indice_carrusel_y = 4 * carrusel_personajes_base.size()
	
	for i in range(filas_infinitas.size()):
		var personaje_nombre = filas_infinitas[i]
		var cartas = cartas_agrupadas[personaje_nombre]
		
		var fila = Control.new()
		fila.name = "Fila_" + str(i) + "_" + personaje_nombre
		fila.position.y = i * ESPACIO_Y 
		fila.size = Vector2(140, 200) 
		fila.pivot_offset = Vector2(70, 100) 
		pista_movimiento.add_child(fila)
		
		for j in range(6):
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(140, 200)
			tex.size = Vector2(140, 200) 
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.position.x = j * ESPACIO_X
			
			if j < cartas.size():
				tex.texture = cartas[j].icono
			else:
				tex.modulate = Color(0.1, 0.1, 0.1, 0.4)
				
			fila.add_child(tex)
			
	show()
	call_deferred("_actualizar_carrusel_visual", true)

func _actualizar_carrusel_visual(instantaneo: bool = false):
	if carrusel_personajes_base.is_empty(): return
	
	var pj_actual = filas_infinitas[indice_carrusel_y]
	var cartas = cartas_agrupadas[pj_actual]
	
	lbl_nombre_carrusel.text = pj_actual
	lbl_conteo_carrusel.text = str(cartas.size()) + " / 6"
	
	retrato_carrusel.texture = null
	for heroe in GlobalGame.party_actual:
		if heroe.nombre == pj_actual:
			retrato_carrusel.texture = heroe.textura_panel
			break
			
	var tween
	if not instantaneo:
		tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var tiempo_anim = 0.0 if instantaneo else 0.25
	
	var target_y = (-indice_carrusel_y * ESPACIO_Y) + CENTRO_PANTALLA_Y
	
	if instantaneo:
		pista_movimiento.position.y = target_y
	else:
		tween.tween_property(pista_movimiento, "position:y", target_y, tiempo_anim)
	
	for i in range(filas_infinitas.size()):
		var fila = pista_movimiento.get_child(i)
		var nombre_fila = filas_infinitas[i]
		
		var distancia_al_centro = abs(i - indice_carrusel_y)
		var target_x = (-indices_carrusel_x[nombre_fila] * ESPACIO_X) + CENTRO_PANTALLA_X
		
		if distancia_al_centro == 0:
			if instantaneo:
				fila.scale = Vector2(1.2, 1.2)
				fila.modulate = Color(1, 1, 1, 1.0)
				fila.position.x = target_x
			else:
				tween.tween_property(fila, "scale", Vector2(1.2, 1.2), tiempo_anim)
				tween.tween_property(fila, "modulate", Color(1, 1, 1, 1.0), tiempo_anim)
				tween.tween_property(fila, "position:x", target_x, tiempo_anim)
				
		elif distancia_al_centro == 1:
			if instantaneo:
				fila.scale = Vector2(0.7, 0.7)
				fila.modulate = Color(1, 1, 1, 0.4)
				fila.position.x = target_x
			else:
				tween.tween_property(fila, "scale", Vector2(0.7, 0.7), tiempo_anim)
				tween.tween_property(fila, "modulate", Color(1, 1, 1, 0.4), tiempo_anim)
				tween.tween_property(fila, "position:x", target_x, tiempo_anim)
				
		else:
			if instantaneo:
				fila.scale = Vector2(0.5, 0.5)
				fila.modulate = Color(1, 1, 1, 0.0)
				fila.position.x = target_x
			else:
				tween.tween_property(fila, "scale", Vector2(0.5, 0.5), tiempo_anim)
				tween.tween_property(fila, "modulate", Color(1, 1, 1, 0.0), tiempo_anim)
				tween.tween_property(fila, "position:x", target_x, tiempo_anim)
