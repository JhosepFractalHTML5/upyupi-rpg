extends CanvasLayer
class_name BattleUI

# --- REFERENCIAS A LA GUI ---
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
@onready var grid_habilidades = $PanelAccion/VBox/GridHabilidades
@onready var contenedor_turnos = $ContenedorTurnos

func _ready():
	menu_acciones.show()
	panel_accion.show()
	var botones_menu = [btn_atacar, btn_defender, btn_habilidades, btn_items, btn_huir]
	for btn in botones_menu:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_menu_activo(activo: bool):
	btn_atacar.disabled = not activo
	btn_defender.disabled = not activo
	btn_habilidades.disabled = not activo
	btn_items.disabled = not activo
	btn_huir.disabled = not activo
	if activo: btn_atacar.grab_focus()

func narrar(texto: String):
	grid_habilidades.hide()
	lbl_narrativa.show()
	lbl_narrativa.text = texto

func agregar_al_log(mensaje: String):
	print(mensaje) 
	texto_log.append_text(mensaje + "\n")

func actualizar_interfaz_party(party_jugador: Array):
	var paneles = contenedor_party.get_children()
	for i in range(paneles.size()):
		if i < party_jugador.size():
			var heroe = party_jugador[i]
			paneles[i].show()
			paneles[i].find_child("LblNombre").text = heroe.nombre
			paneles[i].find_child("LblPV").text = "PV: " + str(heroe.pv_actuales) + "/" + str(heroe.pv_maximos)
			paneles[i].find_child("LblPH").text = "PH: " + str(heroe.ph_actuales) + "/" + str(heroe.ph_maximos)
			var lbl_pt = paneles[i].find_child("LblPT")
			if lbl_pt: lbl_pt.text = "PT: " + str(heroe.pt_actuales) + "/" + str(heroe.pt_maximos)
		else:
			paneles[i].hide()

func actualizar_linea_turnos(combatientes: Array, turno_actual: int, party_jugador: Array):
	if not contenedor_turnos: return
	for hijo in contenedor_turnos.get_children():
		hijo.queue_free()
		
	var futuros_turnos = []
	for i in range(turno_actual, combatientes.size()):
		var c = combatientes[i]
		if c.pv_actuales > 0: futuros_turnos.append(c)
			
	for i in range(futuros_turnos.size()):
		var c = futuros_turnos[i]
		var nodo_visual = null
		
		if c.get("icono_timeline") and c.icono_timeline != null:
			var img = TextureRect.new()
			img.texture = c.icono_timeline
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.custom_minimum_size = Vector2(32, 32) 
			nodo_visual = img
		else:
			var lbl = Label.new()
			var sigla = ""
			if party_jugador.has(c):
				sigla = c.nombre.substr(0, 2)
				lbl.modulate = Color("88ccff")
			else:
				sigla = "En" if not c.nombre.ends_with("2") else "E2"
				lbl.modulate = Color("ff6666")
			lbl.text = sigla
			nodo_visual = lbl
		
		if i == 0: nodo_visual.modulate = Color("ffff00") 
		contenedor_turnos.add_child(nodo_visual)
		
		if i < futuros_turnos.size() - 1:
			var sep = Label.new()
			sep.text = ">"
			sep.modulate = Color(1, 1, 1, 0.5)
			contenedor_turnos.add_child(sep)
