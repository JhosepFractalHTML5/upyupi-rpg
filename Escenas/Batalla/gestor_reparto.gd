extends Node

signal reparto_finalizado

var items_a_distribuir: Array[Item] = []
var item_en_reparto: Item = null
var party_jugador: Array[CharacterStats] = []
var ui_ref = null

func iniciar_reparto(items: Array, party: Array, interfaz):
	items_a_distribuir = items.duplicate()
	party_jugador = party
	ui_ref = interfaz
	
	# Conectamos la señal de la UI hacia nosotros mágicamente
	if not ui_ref.heroe_elegido_para_item.is_connected(_on_heroe_elegido_para_item):
		ui_ref.heroe_elegido_para_item.connect(_on_heroe_elegido_para_item)
		
	_mostrar_siguiente_item()

func _mostrar_siguiente_item():
	if items_a_distribuir.size() > 0:
		item_en_reparto = items_a_distribuir.pop_front()
		ui_ref.abrir_menu_reparto(item_en_reparto, party_jugador)
	else:
		item_en_reparto = null
		ui_ref.narrar("¡Se han recogido todos los objetos!\nPresiona 'Aceptar' para continuar...")
		emit_signal("reparto_finalizado")

func _on_heroe_elegido_para_item(heroe: CharacterStats):
	if item_en_reparto != null:
		var item_caido = heroe.recibir_item_batalla(item_en_reparto)
		
		if item_caido == null:
			ui_ref.narrar("¡" + heroe.nombre + " guardó " + item_en_reparto.nombre + " en sus bolsillos!")
		else:
			ui_ref.narrar("¡Bolsillos llenos! " + heroe.nombre + " empuja " + item_en_reparto.nombre + " en su inventario...\n¡Pero " + item_caido.nombre + " cae al vacío y se pierde!")
			ui_ref.agregar_al_log("[PÉRDIDA] " + item_caido.nombre + " empujado al abismo por " + item_en_reparto.nombre + ".")
		
		if item_caido == null:
			await get_tree().create_timer(1.2).timeout
		else:
			await get_tree().create_timer(2.2).timeout
		
		_mostrar_siguiente_item()
