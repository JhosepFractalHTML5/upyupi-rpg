extends CanvasLayer

@onready var contenedor_personajes = $ContenedorPersonajes

# Nodos de abajo
@onready var btn_items = $ContenedorAbajo/FondoOpciones/HBoxContainer/BtnItems
@onready var lbl_whenes = $ContenedorAbajo/FondoWhenes/LblWhenes

# --- NUEVOS NODOS (FASE 1) ---
@onready var panel_categorias = $PanelCategoriasItems
@onready var btn_consumibles = $PanelCategoriasItems/VBox/BtnConsumibles
@onready var btn_coleccion = $PanelCategoriasItems/VBox/BtnColeccion
@onready var btn_claves = $PanelCategoriasItems/VBox/BtnClaves

# --- REFERENCIAS AL INVENTARIO VISUAL ---
@onready var panel_gran_inventario = $PanelGranInventario
@onready var panel_subcat_coleccion = $PanelSubcategoriasColeccion
@onready var btn_cartas = $PanelSubcategoriasColeccion/VBox/BtnCartas
@onready var btn_fotos = $PanelSubcategoriasColeccion/VBox/BtnFotos
@onready var btn_skins = $PanelSubcategoriasColeccion/VBox/BtnSkins

# --- REFERENCIAS DEL CARRUSEL ---
@onready var panel_carrusel = $PanelCarruselCartas

var personaje_viendo_inventario: CharacterStats = null
var item_a_usar: Item = null # <-- ¡NUEVA! Recuerda qué ítem seleccionaste

# --- MÁQUINA DE ESTADOS ---
enum EstadoMenu { 
	PRINCIPAL, 
	SELECCIONANDO_CATEGORIA_ITEMS, 
	SELECCIONANDO_PJ_ITEMS, 
	VIENDO_INVENTARIO, 
	SELECCIONANDO_OBJETIVO_ITEM,
	SELECCIONANDO_SUBCAT_COLECCION,
	VIENDO_CARRUSEL_CARTAS
}
var estado_actual = EstadoMenu.PRINCIPAL

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if panel_categorias: panel_categorias.hide() 
	if panel_gran_inventario: panel_gran_inventario.hide() 
	if panel_subcat_coleccion: panel_subcat_coleccion.hide()
	if panel_carrusel: panel_carrusel.hide()
	
	if btn_cartas: btn_cartas.pressed.connect(_on_btn_cartas_pressed)
	if btn_fotos: btn_fotos.pressed.connect(_on_btn_fotos_pressed)
	if btn_skins: btn_skins.pressed.connect(_on_btn_skins_pressed)
	if btn_items: btn_items.pressed.connect(_on_btn_items_pressed)
	if btn_consumibles: btn_consumibles.pressed.connect(_on_btn_consumibles_pressed)
	if btn_coleccion: btn_coleccion.pressed.connect(_on_btn_coleccion_pressed)
	if btn_claves: btn_claves.pressed.connect(_on_btn_claves_pressed)
	
	contenedor_personajes.personaje_seleccionado.connect(_on_personaje_seleccionado)
	contenedor_personajes.personaje_seleccionado.connect(_on_personaje_seleccionado)
	if panel_gran_inventario:
		panel_gran_inventario.item_seleccionado_para_uso.connect(_preparar_uso_de_item)

func _input(event):
	if GestorDialogos.dialogo_activo: return
	
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		
		if visible:
			# --- LA ESCALERA DE RETROCESO (Corregida y Limpia) ---
			
			# ¡NUEVO! Volver del carrusel al submenú de Colección
			if estado_actual == EstadoMenu.VIENDO_CARRUSEL_CARTAS:
				cambiar_estado(EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION)
			
			# 1. Si estamos a punto de curar a alguien, cancelamos y volvemos a la mochila
			elif estado_actual == EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM:
				cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)
				panel_gran_inventario.abrir(personaje_viendo_inventario) # <--- MAGIA MODULAR
				
			# 2. Si estamos en la mochila, la cerramos y volvemos a los personajes
			elif estado_actual == EstadoMenu.VIENDO_INVENTARIO:
				panel_gran_inventario.hide() 
				cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS) 
				
			# 3. Volver de las subcategorías a las categorías principales
			elif estado_actual == EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION:
				cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)
				
			# 4. Si estamos en los personajes, volvemos a las categorías
			elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
				cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)
				
			# 5. Si estamos en categorías, volvemos a las opciones principales
			elif estado_actual == EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS:
				cambiar_estado(EstadoMenu.PRINCIPAL)
				
			# 6. Salir del menú por completo
			else:
				cerrar_menu()
		else:
			abrir_menu()

func abrir_menu():
	show()
	actualizar_menu()
	get_tree().paused = true
	cambiar_estado(EstadoMenu.PRINCIPAL) 

func cerrar_menu():
	hide()
	get_tree().paused = false

func cambiar_estado(nuevo_estado):
	if panel_carrusel: panel_carrusel.hide()
	estado_actual = nuevo_estado
	
	# --- ¡NUEVO! Ocultar personajes si estamos viendo la mochila grande ---	
	if estado_actual == EstadoMenu.VIENDO_INVENTARIO:
		contenedor_personajes.hide()
	else:
		contenedor_personajes.show()
		
	var paneles = contenedor_personajes.get_children()
	
	# 1. Apagamos "lo extra" por defecto
	if panel_categorias: panel_categorias.hide()
	if panel_subcat_coleccion: panel_subcat_coleccion.hide()
	if panel_carrusel: panel_carrusel.hide()
	contenedor_personajes.quitar_foco()
	
	# 2. Encendemos solo lo que el estado actual necesita
	if estado_actual == EstadoMenu.PRINCIPAL:
		print("[MENÚ] Opciones Principales")
		btn_items.grab_focus()
		
	elif estado_actual == EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS:
		print("[MENÚ] Eligiendo Categoría")
		if panel_categorias: 
			panel_categorias.show()
			btn_consumibles.grab_focus()
			
	elif estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		print("[MENÚ] ¿Qué mochila vemos?")
		if panel_categorias: panel_categorias.show() 
		
		# ¡MAGIA MODULAR! Delegamos el encender el foco
		contenedor_personajes.preparar_foco()
		
	elif estado_actual == EstadoMenu.VIENDO_INVENTARIO:
		print("[MENÚ] Navegando por el inventario grande")
	
	# --- ¡NUEVO ESTADO! ---
	elif estado_actual == EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM:
		print("[MENÚ] ¿A quién le aplicamos el ítem?")
		
		# Ocultamos el inventario gigante y traemos de vuelta a los personajes
		panel_gran_inventario.hide()
		contenedor_personajes.show()
		
		contenedor_personajes.preparar_foco()
			
	# --- ¡NUEVO ESTADO! ---
	elif estado_actual == EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION:
		print("[MENÚ] Eligiendo Subcategoría de Colección")
		if panel_categorias: panel_categorias.show()
		if panel_subcat_coleccion: 
			panel_subcat_coleccion.show()
			btn_cartas.grab_focus()
			
	# --- ¡NUEVO ESTADO: CARRUSEL! ---
	elif estado_actual == EstadoMenu.VIENDO_CARRUSEL_CARTAS:
		print("[MENÚ] Entrando al sistema de Carrusel...")
		contenedor_personajes.hide()
		if panel_categorias: panel_categorias.hide()
		if panel_subcat_coleccion: panel_subcat_coleccion.hide()
		if panel_carrusel: panel_carrusel.show()

# --- ACCIONES DE BOTONES ---

func _on_btn_items_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_CATEGORIA_ITEMS)

func _on_btn_consumibles_pressed():
	cambiar_estado(EstadoMenu.SELECCIONANDO_PJ_ITEMS)

func _on_btn_coleccion_pressed():
	# Ahora en lugar del print, abrimos el sub-menú
	cambiar_estado(EstadoMenu.SELECCIONANDO_SUBCAT_COLECCION)

# --- PLACEHOLDERS DE SUBCATEGORÍAS ---
func _on_btn_cartas_pressed():
	print("[SISTEMA] Abriendo Carrusel...")
	# ¡Le pasamos el inventario de cartas y él hace todo el trabajo!
	panel_carrusel.abrir(GlobalGame.inventario_cartas)
	cambiar_estado(EstadoMenu.VIENDO_CARRUSEL_CARTAS)

func _on_btn_fotos_pressed():
	print("[SISTEMA] Se ha presionado la sección de FotosRoll")

func _on_btn_skins_pressed():
	print("[SISTEMA] Se ha presionado la sección de Skins (Aún no implementado)")

func _on_btn_claves_pressed():
	print("[SISTEMA] Has seleccionado la Mochila de Objetos Clave Global")

func _on_personaje_seleccionado(indice: int):
	if estado_actual == EstadoMenu.SELECCIONANDO_PJ_ITEMS:
		var personaje = GlobalGame.party_actual[indice]
		personaje_viendo_inventario = personaje # Nos acordamos de quién es la mochila
		panel_gran_inventario.abrir(personaje)  # <--- MAGIA MODULAR
		cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)
		
	# --- ¡AQUÍ SE USA EL OBJETO! ---
	elif estado_actual == EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM:
		var objetivo_seleccionado = GlobalGame.party_actual[indice]
		
		# 1. Aplicamos el efecto
		if item_a_usar.objetivo == "todos_aliados":
			for aliado in GlobalGame.party_actual:
				item_a_usar.usar(personaje_viendo_inventario, aliado, null)
		else:
			item_a_usar.usar(personaje_viendo_inventario, objetivo_seleccionado, null)
			
		# 2. Eliminamos la poción
		personaje_viendo_inventario.inventario.erase(item_a_usar)
		
		# 3. Actualizamos las barras
		actualizar_menu()
		
		# 4. ¿Quedan más pociones iguales?
		var tiene_mas = false
		var siguiente_instancia = null
		
		for i in personaje_viendo_inventario.inventario:
			if i != null and i.nombre == item_a_usar.nombre:
				tiene_mas = true
				siguiente_instancia = i
				break
				
		if tiene_mas:
			item_a_usar = siguiente_instancia
		else:
			cambiar_estado(EstadoMenu.VIENDO_INVENTARIO)
			panel_gran_inventario.abrir(personaje_viendo_inventario) # <--- MAGIA MODULAR

func _preparar_uso_de_item(item: Item):
	item_a_usar = item
	cambiar_estado(EstadoMenu.SELECCIONANDO_OBJETIVO_ITEM)

func actualizar_menu():
	if lbl_whenes: 
		lbl_whenes.text = "Whenes: " + str(GlobalGame.whenes_actuales)
	
	contenedor_personajes.actualizar_personajes()
