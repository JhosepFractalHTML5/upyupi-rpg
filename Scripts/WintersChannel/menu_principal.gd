extends CanvasLayer

@onready var contenedor_personajes = $ContenedorPersonajes

# --- NUEVOS NODOS ---
@onready var btn_items = $ContenedorAbajo/FondoOpciones/HBoxContainer/BtnItems
@onready var lbl_whenes = $ContenedorAbajo/FondoWhenes/LblWhenes

# --- MÁQUINA DE ESTADOS ---
enum EstadoMenu { PRINCIPAL, SELECCIONANDO_PJ_ITEMS }
var estado_actual = EstadoMenu.PRINCIPAL

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	# Conectamos el botón de Items por código
	if btn_items:
		btn_items.pressed.connect(_on_btn_items_pressed)
		
	# Conectamos los botones invisibles de los personajes
	var paneles = contenedor_personajes.get_children()
	for i in range(paneles.size()):
		var btn = paneles[i].get_node_or_null("BtnSeleccionar")
		if btn:
			# Le pasamos el índice (i) para saber a qué personaje elegimos
			btn.pressed.connect(_on_personaje_seleccionado.bind(i))

func _input(event):
	if GestorDialogos.dialogo_activo: return
	
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		
		if visible:
			# Si estamos en un sub-menú, "ui_cancel" (B/Esc) nos devuelve a las opciones principales
			if estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
				cambiar_estado(EstadoMenu.PRINCIPAL)
			else:
				# Si ya estamos en la raíz, cerramos el menú
				cerrar_menu()
		else:
			abrir_menu()

func abrir_menu():
	show()
	actualizar_menu()
	get_tree().paused = true
	cambiar_estado(EstadoMenu.PRINCIPAL) # Siempre abrimos en las opciones de abajo

func cerrar_menu():
	hide()
	get_tree().paused = false

func cambiar_estado(nuevo_estado):
	estado_actual = nuevo_estado
	
	var paneles = contenedor_personajes.get_children()
	
	if estado_actual == EstadoMenu.PRINCIPAL:
		print("[MENÚ] Estado: Opciones Principales")
		# Activamos las opciones y apagamos los paneles
		btn_items.grab_focus()
		
		for i in range(paneles.size()):
			var btn = paneles[i].get_node_or_null("BtnSeleccionar")
			if btn: btn.focus_mode = Control.FOCUS_NONE # No se pueden seleccionar con teclado
			
	elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		print("[MENÚ] Estado: ¿A quién le vemos los items?")
		# Permitimos seleccionar personajes (solo los que existen en la party)
		for i in range(paneles.size()):
			var btn = paneles[i].get_node_or_null("BtnSeleccionar")
			if btn:
				if i < GlobalGame.party_actual.size():
					btn.focus_mode = Control.FOCUS_ALL
				else:
					btn.focus_mode = Control.FOCUS_NONE
					
		# Le damos el foco al primer personaje (Jhosep)
		var primer_btn = paneles[0].get_node_or_null("BtnSeleccionar")
		if primer_btn: primer_btn.grab_focus()

# --- ACCIONES DE BOTONES ---
func _on_btn_items_pressed():
	# Cuando hacemos clic o enter en "Items"
	cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS)

func _on_personaje_seleccionado(indice: int):
	# Cuando hacemos clic o enter en un personaje
	if estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		var personaje = GlobalGame.party_actual[indice]
		print("[MENÚ] Abriendo mochila de: ", personaje.nombre)
		# TODO: Aquí luego abriremos el panel de inventario de este personaje

func actualizar_menu():
	# --- ACTUALIZAR DINERO ---
	if lbl_whenes:
		lbl_whenes.text = "Whenes: " + str(GlobalGame.whenes_actuales)
	
	var paneles = contenedor_personajes.get_children()
	for i in range(paneles.size()):
		var panel = paneles[i]
		panel.show() 
		
		var nodo_fondo = panel.get_node_or_null("FondoPanel") as TextureRect
		var nodo_pose = panel.get_node_or_null("SpritePose") as TextureRect
		var btn_seleccionar = panel.get_node_or_null("BtnSeleccionar")
		
		if i < GlobalGame.party_actual.size():
			var heroe = GlobalGame.party_actual[i]
			
			panel.modulate = Color(1, 1, 1, 1)
			
			# Habilitamos su botón invisible
			if btn_seleccionar: btn_seleccionar.disabled = false
			
			# --- TEXTOS DE ESTADÍSTICAS (¡Restaurados!) ---
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
			
			# --- LLENADO DE BARRAS VISUALES ---
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
			
			# --- CAPAS DE ARTE ---
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
			
			# Desactivamos el botón si no hay personaje
			if btn_seleccionar: btn_seleccionar.disabled = true
			
			if nodo_fondo: nodo_fondo.hide()
			if nodo_pose: nodo_pose.hide()
