extends CanvasLayer

@onready var contenedor = $ContenedorPersonajes

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if visible:
			cerrar_menu()
		else:
			abrir_menu()

func abrir_menu():
	show()
	actualizar_menu()
	get_tree().paused = true # Pausamos el movimiento del Overworld

func cerrar_menu():
	hide()
	get_tree().paused = false # El juego continúa

func actualizar_menu():
	var paneles = contenedor.get_children()
	
	for i in range(paneles.size()):
		var panel = paneles[i]
		
		# Forzamos a que el panel se muestre para que el GridContainer no colapse
		panel.show() 
		
		var nodo_fondo = panel.get_node_or_null("FondoPanel") as TextureRect
		var nodo_pose = panel.get_node_or_null("SpritePose") as TextureRect
		
		if i < GlobalGame.party_actual.size():
			var heroe = GlobalGame.party_actual[i]
			
			# Restauramos la visibilidad y el control
			panel.modulate = Color(1, 1, 1, 1)
			panel.mouse_filter = Control.MOUSE_FILTER_STOP 
			
			# --- TEXTOS DE ESTADÍSTICAS ---
			panel.get_node("LblNombre").text = heroe.nombre
			panel.get_node("LblClase").text = heroe.clase
			panel.get_node("LblNivel").text = "Nv. " + str(heroe.nivel)
			
			# ¡Limpiados para ahorrar espacio! Solo mostramos la vida/magia actual
			panel.get_node("LblPV").text = "PV: " + str(heroe.pv_actuales)
			panel.get_node("LblPH").text = "PH: " + str(heroe.ph_actuales)
			
			# NUEVO: Etiqueta de Tensión
			panel.get_node("LblPT").text = "PT: " + str(heroe.pt_actuales)
			
			var exp_faltante = heroe.exp_necesaria_proximo_nivel - heroe.exp_actual
			panel.get_node("LblExp").text = "EXP: " + str(heroe.exp_actual) + " (Faltan: " + str(exp_faltante) + ")"
			
			var items_ocupados = 0
			for item in heroe.inventario:
				if item != null: items_ocupados += 1
			panel.get_node("LblInv").text = "Bolsillos: " + str(items_ocupados) + " / " + str(heroe.max_items)
			
			# --- NUEVO: LLENADO DE BARRAS VISUALES ---
			var barra_pv = panel.get_node_or_null("BarraPV")
			if barra_pv:
				barra_pv.max_value = heroe.pv_maximos
				barra_pv.value = heroe.pv_actuales
				
			var barra_ph = panel.get_node_or_null("BarraPH")
			if barra_ph:
				barra_ph.max_value = heroe.ph_maximos
				barra_ph.value = heroe.ph_actuales
				
			# NUEVO: Barra de Tensión
			var barra_pt = panel.get_node_or_null("BarraPT")
			if barra_pt:
				barra_pt.max_value = heroe.pt_maximos
				barra_pt.value = heroe.pt_actuales
				
			var barra_exp = panel.get_node_or_null("BarraExp")
			if barra_exp:
				barra_exp.max_value = heroe.exp_necesaria_proximo_nivel
				barra_exp.value = heroe.exp_actual
			
			# --- CAPAS DE ARTE (Fotoroll + Pose Chistosa) ---
			if nodo_fondo:
				if heroe.textura_panel != null:
					nodo_fondo.show()
					nodo_fondo.texture = heroe.textura_panel
				else:
					nodo_fondo.hide()
					
			if nodo_pose:
				if heroe.get("textura_pose_menu") != null and heroe.textura_pose_menu != null:
					nodo_pose.show()
					nodo_pose.texture = heroe.textura_pose_menu
				else:
					nodo_pose.hide() 
			
		else:
			# --- TRUCO FANTASMA ---
			panel.modulate = Color(1, 1, 1, 0)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			if nodo_fondo: nodo_fondo.hide()
			if nodo_pose: nodo_pose.hide()
