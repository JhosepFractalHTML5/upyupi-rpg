extends StaticBody2D

@export_category("Configuración de Batalla")
@export var oleada_1: Array[CharacterStats]
@export var oleada_2: Array[CharacterStats]
@export var oleada_3: Array[CharacterStats]

@export_category("Diálogo")
# Esto te permitirá ponerle un diálogo distinto a cada enemigo desde el Inspector
@export var id_dialogo: String = "prueba_1" 

# Aquí guardaremos al jugador cuando se acerque
var jugador_en_rango: Node2D = null

func _ready():
	# Conectamos las señales del Area2D por código para evitar errores
	if has_node("AreaInteraccion"):
		$AreaInteraccion.body_entered.connect(_on_jugador_entra)
		$AreaInteraccion.body_exited.connect(_on_jugador_sale)
	else:
		print("¡Falta añadir el nodo AreaInteraccion a ", name, "!")

# Cuando un cuerpo entra al área grande...
func _on_jugador_entra(body):
	# Verificamos que sea el Jugador (asegúrate de que el nodo de Jhosep esté en el grupo "Jugador")
	if body.is_in_group("Jugador"):
		jugador_en_rango = body

# Cuando el cuerpo sale del área...
func _on_jugador_sale(body):
	if body == jugador_en_rango:
		jugador_en_rango = null

# Escuchamos los botones del teclado/mando
# Escuchamos los botones del teclado/mando
func _unhandled_input(event):
	if jugador_en_rango and event.is_action_pressed("ui_accept"):
		
		# --- EL SEGURO ANTI-SPAM ---
		# Verificamos que NO haya un diálogo Y que Jhosep NO esté ya en medio de una cinemática
		if not GestorDialogos.dialogo_activo and not jugador_en_rango.en_cinematica:
			
			get_viewport().set_input_as_handled()
			var protagonista = jugador_en_rango 
			
			# 1. Bloqueamos al jugador INMEDIATAMENTE
			# Al ponerse en 'true', el seguro de arriba impedirá que el botón Aceptar vuelva a entrar aquí.
			protagonista.en_cinematica = true
			
			# 2. LA RUTA DE MOVIMIENTO (Ahora es intocable)
			await protagonista.get_node("Ruta").saltar()
			await protagonista.get_node("Ruta").esperar(0.5)
			await protagonista.get_node("Ruta").mover(Vector2.DOWN, 1.5)
			
			# 3. Lanzamos el diálogo
			GestorDialogos.iniciar_dialogo(id_dialogo, protagonista)
			
			# 4. Le quitamos la cinemática
			protagonista.en_cinematica = false
			
			

# --- TU FUNCIÓN DE BATALLA ORIGINAL (Intacta) ---
func iniciar_encuentro():
	var todas_las_oleadas = []
	
	if oleada_1.size() > 0: todas_las_oleadas.append(oleada_1)
	if oleada_2.size() > 0: todas_las_oleadas.append(oleada_2)
	if oleada_3.size() > 0: todas_las_oleadas.append(oleada_3)
	
	if todas_las_oleadas.is_empty():
		print("¡Artista, te olvidaste de poner enemigos en este combate!")
		return
	
	var ruta_mapa_actual = get_tree().current_scene.scene_file_path
	
	var jugador = get_tree().get_first_node_in_group("Jugador")
	if jugador:
		GlobalGame.posicion_jugador_mapa = jugador.global_position
	else:
		GlobalGame.posicion_jugador_mapa = self.global_position 
		
	GlobalGame.mapa_anterior_ruta = ruta_mapa_actual
	GlobalGame.entrar_a_batalla(todas_las_oleadas, ruta_mapa_actual)
