extends Resource
class_name ItemConsumible

@export var nombre: String = "Poción"
@export_multiline var descripcion: String = "Restaura 50 PV."
@export var icono: Texture2D
@export_enum("aliado", "enemigo", "usuario") var objetivo: String = "aliado"
@export_enum("CURAR_PV", "CURAR_PH", "CURAR_PT", "REVIVIR") var tipo_efecto: String = "CURAR_PV"
@export var poder: int = 50
