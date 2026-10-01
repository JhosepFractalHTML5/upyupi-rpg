extends Node

signal objetivo_confirmado(objetivo: CharacterStats)
signal seleccion_cancelada

var activo: bool = false
var indice_actual: int = 0
var objetivos_posibles: Array = []
var bm_ref = null
var ui_ref = null

func iniciar(objetivos: Array, battle_manager, interfaz):
	objetivos_posibles = objetivos
	bm_ref = battle_manager
	ui_ref = interfaz
	indice_actual = 0
	activo = true
	_actualizar_texto()

func _process(_delta):
	# ¡Solo calculamos matemáticas si estamos apuntando a alguien!
	if not activo or objetivos_posibles.is_empty():
		return

	var objetivo_seleccionado = objetivos_posibles[indice_actual]
	var alpha_parpadeo = 0.4 + abs(sin(Time.get_ticks_msec() * 0.005) * 0.6)

	# Limpiamos visualmente a todos y encendemos solo al apuntado
	for obj in objetivos_posibles:
		var nodo = bm_ref._obtener_nodo_visual(obj)
		if is_instance_valid(nodo):
			if obj == objetivo_seleccionado:
				nodo.modulate.a = alpha_parpadeo
			else:
				nodo.modulate.a = 1.0

func _unhandled_input(event):
	if not activo: return

	if event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		indice_actual = (indice_actual + 1) % objetivos_posibles.size()
		_actualizar_texto()
		
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		indice_actual = (indice_actual - 1 + objetivos_posibles.size()) % objetivos_posibles.size()
		_actualizar_texto()
		
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirmar()
		
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancelar()

func _actualizar_texto():
	var obj = objetivos_posibles[indice_actual]
	if is_instance_valid(obj):
		ui_ref.narrar("Selecciona objetivo:\n> " + obj.nombre + " <")

func _confirmar():
	activo = false
	_limpiar_visuales()
	emit_signal("objetivo_confirmado", objetivos_posibles[indice_actual])

func _cancelar():
	activo = false
	_limpiar_visuales()
	emit_signal("seleccion_cancelada")

func _limpiar_visuales():
	# Nos aseguramos de que nadie se quede transparente al terminar
	for obj in objetivos_posibles:
		var nodo = bm_ref._obtener_nodo_visual(obj)
		if is_instance_valid(nodo):
			nodo.modulate.a = 1.0
