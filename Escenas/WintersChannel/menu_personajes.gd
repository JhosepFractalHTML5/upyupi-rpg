extends Control # O HBoxContainer/VBoxContainer, dependiendo de qué nodo sea

# El menú principal escuchará este "grito" para saber a quién elegiste
signal personaje_seleccionado(indice: int)

func _ready():
	# Conectamos todos los botones internos hacia nuestra señal
	var paneles = get_children()
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn:
			btn.pressed.connect(func(): emit_signal("personaje_seleccionado", i))

func actualizar_personajes():
	var paneles = get_children()
	for i in range(paneles.size()):
		var panel = paneles[i]
		panel.show() 
		
		var nodo_fondo = panel.get_node_or_null("FondoPanel") as TextureRect
		var nodo_pose = panel.get_node_or_null("SpritePose") as TextureRect
		var btn_seleccionar = panel.get_node_or_null("BtnSeleccionar")
		
		if i < GlobalGame.party_actual.size():
			var heroe = GlobalGame.party_actual[i]
			panel.modulate = Color(1, 1, 1, 1)
			if btn_seleccionar: btn_seleccionar.disabled = false
			
			panel.get_node("LblNombre").text = heroe.nombre
			panel.get_node("LblClase").text = heroe.clase
			panel.get_node("LblNivel").text = "Nv. " + str(heroe.nivel)
			panel.get_node("LblPV").text = "PV: " + str(heroe.pv_actuales)
			panel.get_node("LblPH").text = "PH: " + str(heroe.ph_actuales)
			panel.get_node("LblPT").text = "PT: " + str(heroe.pt_actuales)
			
			var exp_faltante = heroe.exp_necesaria_proximo_nivel - heroe.exp_actual
			panel.get_node("LblExp").text = "EXP: " + str(heroe.exp_actual) + " (Faltan: " + str(exp_faltante) + ")"
			
			var items_ocupados = 0
			for item in heroe.inventario:
				if item != null: items_ocupados += 1
			panel.get_node("LblInv").text = "Bolsillos: " + str(items_ocupados) + " / " + str(heroe.max_items)
			
			var barra_pv = panel.get_node_or_null("BarraPV")
			if barra_pv:
				barra_pv.max_value = heroe.pv_maximos
				barra_pv.value = heroe.pv_actuales
				
			var barra_ph = panel.get_node_or_null("BarraPH")
			if barra_ph:
				barra_ph.max_value = heroe.ph_maximos
				barra_ph.value = heroe.ph_actuales
				
			var barra_pt = panel.get_node_or_null("BarraPT")
			if barra_pt:
				barra_pt.max_value = heroe.pt_maximos
				barra_pt.value = heroe.pt_actuales
				
			var barra_exp = panel.get_node_or_null("BarraExp")
			if barra_exp:
				barra_exp.max_value = heroe.exp_necesaria_proximo_nivel
				barra_exp.value = heroe.exp_actual
			
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
			panel.modulate = Color(1, 1, 1, 0)
			if btn_seleccionar: btn_seleccionar.disabled = true
			if nodo_fondo: nodo_fondo.hide()
			if nodo_pose: nodo_pose.hide()

func preparar_foco():
	var paneles = get_children()
	var primer_btn_valido = null
	
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn:
			if i < GlobalGame.party_actual.size():
				btn.focus_mode = Control.FOCUS_ALL
				if primer_btn_valido == null:
					primer_btn_valido = btn
			else:
				btn.focus_mode = Control.FOCUS_NONE
				
	if primer_btn_valido:
		primer_btn_valido.grab_focus()

func quitar_foco():
	var paneles = get_children()
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn:
			btn.focus_mode = Control.FOCUS_NONE
