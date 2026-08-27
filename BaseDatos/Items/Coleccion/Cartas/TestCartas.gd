extends StaticBody2D

var jugador_en_rango: Node2D = null
var numero_interaccion: int = 0

func _ready():
	if has_node("AreaInteraccion"):
		$AreaInteraccion.body_entered.connect(_on_jugador_entra)
		$AreaInteraccion.body_exited.connect(_on_jugador_sale)

func _on_jugador_entra(body):
	if body.is_in_group("Jugador"):
		jugador_en_rango = body

func _on_jugador_sale(body):
	if body == jugador_en_rango:
		jugador_en_rango = null

func _unhandled_input(event):
	# Si ya hay un diálogo o no hay nadie cerca, no hacemos nada
	if GestorDialogos.dialogo_activo or not jugador_en_rango:
		return
		
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		
		# Dependiendo de cuántas veces hemos hablado, damos una carta distinta
		match numero_interaccion:
			0:
				var carta_1 = load("res://BaseDatos/Items/Coleccion/Cartas/Carta_EscudoHumano.tres")
				GlobalGame.inventario_cartas.append(carta_1)
				print("[NPC] ¡Toma tu primera carta: Escudo Humano!")
				# Si tienes tu sistema de diálogos listo, puedes descomentar esto:
				# GestorDialogos.mostrar_texto("¡Jhosep obtuvo la Carta Escudo Humano!")
			1:
				var carta_2 = load("res://BaseDatos/Items/Coleccion/Cartas/Carta_CorteMultiple.tres")
				GlobalGame.inventario_cartas.append(carta_2)
				print("[NPC] ¡Aquí tienes otra: Corte Múltiple!")
			2:
				var carta_3 = load("res://BaseDatos/Items/Coleccion/Cartas/Carta_EnMiDefensa.tres")
				GlobalGame.inventario_cartas.append(carta_3)
				print("[NPC] ¡Esta es la última: En Mi Defensa!")
			3:
				var carta_4 = load("res://BaseDatos/Items/Coleccion/Cartas/Carta_Bait.tres")
				GlobalGame.inventario_cartas.append(carta_4)
				print("[NPC] ¡Esta es la última: BAIT!")
			4:
				var carta_5 = load("res://BaseDatos/Items/Coleccion/Cartas/Carta_CocinaRapida.tres")
				GlobalGame.inventario_cartas.append(carta_5)
				print("[NPC] ¡Esta es la última: COCINA RAPIDA!")
			_:
				print("[NPC] Ya te di todas las cartas que tenía. ¡Ve a revisar tu menú!")
				
		# Aumentamos el contador para la próxima vez que presiones "Aceptar"
		if numero_interaccion < 5:
			numero_interaccion += 1
