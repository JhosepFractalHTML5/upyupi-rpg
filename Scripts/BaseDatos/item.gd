extends Resource
class_name Item

@export_group("Información General")
@export var nombre: String = "Objeto Desconocido"
@export_multiline var descripcion: String = "..."
@export var icono: Texture2D

@export_group("Categorización")
@export_enum("Consumible", "Coleccion", "Clave") var categoria: String = "Consumible"
@export_enum("Ninguna", "Refuerzo", "Ofensivo", "Cartas", "FotosRoll", "Skins", "Aventura", "Secundarias", "Utilidades") var subcategoria: String = "Ninguna"

@export_group("Datos de Combate (Solo Consumibles)")
@export_enum("aliado", "enemigo", "usuario", "todos_aliados", "todos_enemigos") var objetivo: String = "aliado"
@export_enum("NINGUNO", "CURAR_PV", "CURAR_PH", "CURAR_PT", "REVIVIR", "DANO_FIJO") var tipo_efecto: String = "NINGUNO"
@export var poder: int = 50

# --- NUEVO: REGLAS DE MUERTE Y RESURRECCIÓN ---
@export var puede_revivir: bool = false 

func usar(usuario: CharacterStats, blanco: CharacterStats, bm: Node = null):
	if categoria != "Consumible":
		return
		
	# --- SEGURO ANTI-ZOMBIES ---
	if blanco.pv_actuales <= 0 and not puede_revivir:
		if bm != null: bm.ui.narrar("¡" + blanco.nombre + " ya es un cadáver... esto no ayudará!")
		return

	# --- CÁLCULO DE FARMACOLOGÍA ---
	var multiplicador_farma = 1.0
	if "farmacologia" in usuario:
		multiplicador_farma = usuario.farmacologia
		
	var efecto_final = int(poder * multiplicador_farma)

	# --- EJECUCIÓN DEL EFECTO ---
	match tipo_efecto:
		"CURAR_PV":
			blanco.pv_actuales = clampi(blanco.pv_actuales + efecto_final, 0, blanco.pv_maximos)
			if bm != null: bm.ui.narrar("¡" + usuario.nombre + " usa " + nombre + " y cura " + str(efecto_final) + " PV a " + blanco.nombre + "!")
			
		"REVIVIR":
			if blanco.pv_actuales <= 0:
				blanco.pv_actuales = clampi(efecto_final, 1, blanco.pv_maximos)
				if bm != null: bm.ui.narrar("¡" + blanco.nombre + " fue arrancado de las garras de la muerte!")
			else:
				if bm != null: bm.ui.narrar("¡No tiene sentido! ¡" + blanco.nombre + " ya está respirando!")
				
		"CURAR_PH":
			blanco.ph_actuales = clampi(blanco.ph_actuales + efecto_final, 0, blanco.ph_maximos)
			if bm != null: bm.ui.narrar("¡" + blanco.nombre + " recupera " + str(efecto_final) + " PH!")
			
		"CURAR_PT":
			blanco.pt_actuales = clampi(blanco.pt_actuales + efecto_final, 0, blanco.pt_maximos)
			if bm != null: bm.ui.narrar("¡" + blanco.nombre + " restaura " + str(efecto_final) + " Puntos de Tensión!")
			
		"DANO_FIJO": 
			blanco.pv_actuales = max(0, blanco.pv_actuales - efecto_final)
			if bm != null: bm.ui.narrar("¡El " + nombre + " le inflige " + str(efecto_final) + " de daño a " + blanco.nombre + "!")
			
	# Pausa dramática solo si estamos en batalla
	if bm != null:
		await bm.get_tree().create_timer(1.0).timeout
