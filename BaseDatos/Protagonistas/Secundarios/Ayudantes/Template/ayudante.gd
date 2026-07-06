extends Resource
class_name Ayudante

@export var nombre: String = "Ayudante"
@export_multiline var descripcion: String = ""
@export var icono: Texture2D

@export_group("Pasivas de Batalla")
@export var bono_exp: float = 0.0 # 0.02 = 2% extra
@export var bono_whenes: float = 0.0 # 0.02 = 2% extra

func ejecutar_asistencia(bm: Node):
	pass
