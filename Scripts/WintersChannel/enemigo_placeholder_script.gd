extends StaticBody2D

@export_category("Configuración de Batalla")
@export var oleada_1: Array[CharacterStats]
@export var oleada_2: Array[CharacterStats]
@export var oleada_3: Array[CharacterStats]

func iniciar_encuentro():
	var todas_las_oleadas = []
	
	# Solo empacamos las oleadas que tengan al menos un enemigo adentro
	if oleada_1.size() > 0: todas_las_oleadas.append(oleada_1)
	if oleada_2.size() > 0: todas_las_oleadas.append(oleada_2)
	if oleada_3.size() > 0: todas_las_oleadas.append(oleada_3)
	
	if todas_las_oleadas.is_empty():
		print("¡Artista, te olvidaste de poner enemigos en este combate!")
		return
	
	var ruta_mapa_actual = get_tree().current_scene.scene_file_path
	
	# Le pasamos el paquete completo de oleadas al cerebro global
	GlobalGame.entrar_a_batalla(todas_las_oleadas, ruta_mapa_actual)
