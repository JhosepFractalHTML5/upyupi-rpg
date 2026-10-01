extends CanvasLayer
class_name BattleUI

# ===== REFERENCIAS A NODES =====
@onready var panel_log = $PanelLog
@onready var menu_acciones = $MenuAcciones
@onready var btn_atacar = $MenuAcciones/BtnAtacar
@onready var btn_defender = $MenuAcciones/BtnDefender
@onready var btn_habilidades = $MenuAcciones/BtnHabilidades
@onready var btn_items = $MenuAcciones/BtnItems
@onready var btn_huir = $MenuAcciones/BtnHuir
@onready var texto_log = $PanelLog/TextoLog
@onready var contenedor_party = $ContenedorParty
@onready var contenedor_enemigos = $ContenedorEnemigos
@onready var retrato_activo = $MenuAcciones/RetratoActivo
@onready var panel_accion = $PanelAccion
@onready var lbl_narrativa = $PanelAccion/VBox/LblNarrativa
@onready var grid_habilidades = $PanelLog/GridHabilidades
@onready var contenedor_turnos = $ContenedorTurnos
@onready var grid_items = $PanelLog/GridItems
@onready var panel_victoria = $PanelVictoria

# ===== ICONOS DE INTERFAZ =====
@export_category("Iconos de Interfaz")
@export var icono_pv: Texture2D

# ===== ICONOS DE ESTADOS =====
@export_category("Iconos de Estados Alterados")
@export var icon_atk_up: Texture2D
@export var icon_atk_down: Texture2D
@export var icon_def_up: Texture2D
@export var icon_def_down: Texture2D
@export var icon_agi_up: Texture2D
@export var icon_agi_down: Texture2D
@export var icon_suerte_up: Texture2D
@export var icon_suerte_down: Texture2D
@export var icon_provocacion: Texture2D
@export var icon_distraido: Texture2D
@export var icon_defensa: Texture2D
@export var icon_enamorado: Texture2D

# ===== VARIABLES GLOBALES =====
signal inversion_completada
signal heroe_elegido_para_item(heroe: CharacterStats)

# ===== INICIALIZACIÓN =====
func _ready():
	panel_victoria.hide()
	menu_acciones.show()
	panel_accion.show()

	var botones_menu = [btn_atacar, btn_defender, btn_habilidades, btn_items, btn_huir]
	for btn in botones_menu:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Conectamos las señales del nuevo panel hacia las señales que el BattleManager ya conoce
	panel_victoria.inversion_completada.connect(func(): emit_signal("inversion_completada"))
	panel_victoria.heroe_elegido_para_item.connect(func(h): emit_signal("heroe_elegido_para_item", h))

func set_menu_activo(activo: bool):
	btn_atacar.disabled = not activo
	btn_defender.disabled = not activo
	btn_habilidades.disabled = not activo
	btn_items.disabled = not activo
	btn_huir.disabled = not activo
	if activo:
		btn_atacar.grab_focus()

func narrar(texto: String):
	lbl_narrativa.show()
	lbl_narrativa.text = texto

func agregar_al_log(mensaje: String):
	print(mensaje)
	texto_log.append_text(mensaje + "\n")
	
# ===== EFECTOS VISUALES =====
var fuerza_temblor: float = 0.0

func _process(delta):
	if fuerza_temblor > 0:
		fuerza_temblor = lerpf(fuerza_temblor, 0.0, 5.0 * delta)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * fuerza_temblor

		if fuerza_temblor < 0.5:
			fuerza_temblor = 0.0
			offset = Vector2.ZERO

func aplicar_temblor(porcentaje_dano: float):
	if porcentaje_dano >= 0.75:
		fuerza_temblor = 30.0
	elif porcentaje_dano >= 0.50:
		fuerza_temblor = 18.0
	elif porcentaje_dano >= 0.25:
		fuerza_temblor = 10.0
	else:
		fuerza_temblor = 4.0

func mostrar_descripcion_item(descripcion: String):
	lbl_narrativa.show()
	lbl_narrativa.text = descripcion

# ===== DIRECTOR DE EFECTOS VISUALES (Fase 1) =====
var timer_estados: Timer
var indice_rotacion_estado: int = 0
var ref_enemigos: Array = []
var ref_sprites: Dictionary = {}

func iniciar_sistema_estados(enemigos: Array, sprites: Dictionary):
	ref_enemigos = enemigos
	ref_sprites = sprites
	if timer_estados == null:
		timer_estados = Timer.new()
		timer_estados.wait_time = 1.0
		timer_estados.autostart = true
		timer_estados.timeout.connect(_rotar_estados_enemigos)
		add_child(timer_estados)
	else:
		timer_estados.start()

func detener_sistema_estados():
	if timer_estados: timer_estados.stop()

func mostrar_numero_flotante(nodo_objetivo: Control, cantidad: int, tipo: String):
	if not is_instance_valid(nodo_objetivo): return

	var color = Color.RED
	if tipo == "atipico": color = Color.PURPLE
	elif tipo == "cura": color = Color.GREEN

	var lbl = Label.new()
	lbl.text = str(cantidad)
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.z_index = 50

	var pos_global = nodo_objetivo.global_position
	lbl.position = pos_global + (nodo_objetivo.size / 2.0) - Vector2(10, 20)
	add_child(lbl) # ¡Se añade a la UI directamente!

	var tween = get_tree().create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 50, 1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(lbl.queue_free)

func animar_parpadeo_enemigo(sprite_enemigo: TextureRect):
	if is_instance_valid(sprite_enemigo):
		var tween = get_tree().create_tween()
		tween.tween_property(sprite_enemigo, "modulate:a", 0.0, 0.1)
		tween.tween_property(sprite_enemigo, "modulate:a", 1.0, 0.1)
		tween.tween_property(sprite_enemigo, "modulate:a", 0.0, 0.1)
		tween.tween_property(sprite_enemigo, "modulate:a", 1.0, 0.1)

func _rotar_estados_enemigos():
	indice_rotacion_estado += 1
	for enemigo in ref_enemigos:
		if not is_instance_valid(enemigo) or not ref_sprites.has(enemigo): continue
		
		var rect = ref_sprites[enemigo]
		if not is_instance_valid(rect): continue

		var nodo_icono = rect.get_node_or_null("IconoEstado")
		if not is_instance_valid(nodo_icono): continue

		var activos = []
		# ¡Como ya estamos en la UI, no necesitamos escribir "ui.icon..."!
		if enemigo.niveles_stat["ataque"] > 0 and icon_atk_up: activos.append(icon_atk_up)
		elif enemigo.niveles_stat["ataque"] < 0 and icon_atk_down: activos.append(icon_atk_down)
		if enemigo.niveles_stat["defensa"] > 0 and icon_def_up: activos.append(icon_def_up)
		elif enemigo.niveles_stat["defensa"] < 0 and icon_def_down: activos.append(icon_def_down)
		if enemigo.niveles_stat["agilidad"] > 0 and icon_agi_up: activos.append(icon_agi_up)
		elif enemigo.niveles_stat["agilidad"] < 0 and icon_agi_down: activos.append(icon_agi_down)
		if enemigo.niveles_stat["suerte"] > 0 and icon_suerte_up: activos.append(icon_suerte_up)
		elif enemigo.niveles_stat["suerte"] < 0 and icon_suerte_down: activos.append(icon_suerte_down)

		if enemigo.turnos_provocacion > 0 and icon_provocacion: activos.append(icon_provocacion)
		if enemigo.turnos_distraido > 0 and icon_distraido: activos.append(icon_distraido)
		if enemigo.turnos_enamorado > 0 and icon_enamorado: activos.append(icon_enamorado)
		if enemigo.esta_defendiendo and icon_defensa: activos.append(icon_defensa)

		if activos.is_empty():
			nodo_icono.hide()
		else:
			nodo_icono.show()
			nodo_icono.texture = activos[indice_rotacion_estado % activos.size()]

# ===== PUENTES HACIA EL POST-BATALLA (Fase 1) =====
func mostrar_pantalla_victoria(party: Array, exp_total: int, niveles_previos: Dictionary, whenes_total: int = 0, items_ganados: Array = []):
	panel_victoria.mostrar_pantalla_victoria(party, exp_total, niveles_previos, whenes_total, items_ganados)

func abrir_menu_inversion(heroe: CharacterStats):
	panel_victoria.abrir_menu_inversion(heroe)

func abrir_menu_reparto(item: Item, party: Array):
	panel_victoria.abrir_menu_reparto(item, party)

# ===== PUENTES DE GENERACIÓN DE MENÚS (Fase 2) =====
func actualizar_inventario_visual(atacante: CharacterStats, manager: Node):
	panel_log.actualizar_inventario(atacante, manager, self)

func actualizar_habilidades_visual(atacante: CharacterStats, manager: Node):
	panel_log.actualizar_habilidades(atacante, manager, self)

# ===== PUENTES HACIA EL MONITOR VITAL (Fase 3) =====
func actualizar_interfaz_party(party_jugador: Array):
	contenedor_party.actualizar_interfaz_party(party_jugador, self)

func animar_turno_activo(heroe_activo: CharacterStats, party_jugador: Array):
	contenedor_party.animar_turno_activo(heroe_activo, party_jugador)

func actualizar_linea_turnos(combatientes: Array, turno_actual: int, party_jugador: Array):
	contenedor_party.actualizar_linea_turnos(combatientes, turno_actual, party_jugador, contenedor_turnos)
