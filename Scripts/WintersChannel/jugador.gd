extends CharacterBody2D
class_name JugadorOverworld

const VELOCIDAD = 150.0

@onready var sprite = $SpriteLider
@onready var anim_player = $AnimadorLider
@onready var raycast = $RayCast2D

# --- SISTEMA DE ACOMPAÑANTE ---
var historial: Array[Dictionary] = []
var max_historial: int = 30 
var anim_actual: String = ""

# ¡CUIDADO! Verifica que esta ruta sea la correcta
var AcompananteEscena = preload("res://Escenas/Almas/Test/acompanante.tscn") 

func _ready():
	# --- TRUCO DE CAPAS ---
	# Activamos la magia del Y-Sorting desde código para asegurarnos
	get_parent().y_sort_enabled = true
	y_sort_enabled = true 
	
	if GlobalGame.party_actual.size() > 0:
		var lider = GlobalGame.party_actual[0]
		if lider.textura_sprite != null:
			sprite.texture = lider.textura_sprite
			sprite.frame = 0
			
	if GlobalGame.party_actual.size() > 1 and AcompananteEscena:
		var acomp = AcompananteEscena.instantiate()
		acomp.lider = self 
		acomp.global_position = self.global_position 
		get_parent().call_deferred("add_child", acomp)

func _physics_process(_delta):
	var direccion = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	if direccion != Vector2.ZERO:
		velocity = direccion * VELOCIDAD
		_actualizar_animacion(direccion)
		
		# --- MIGAJAS INTELIGENTES ---
		# ¡Solo dejamos migajas si nos movemos! Así el seguidor no nos pisa.
		historial.push_front({"pos": global_position, "anim": anim_actual})
		
		if historial.size() > max_historial:
			historial.pop_back()
	else:
		velocity = Vector2.ZERO
		anim_player.stop()
		
	move_and_slide()

func _actualizar_animacion(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim_actual = "caminar_der"
			raycast.target_position = Vector2(30, 0) # Rayo a la derecha
		else:
			anim_actual = "caminar_izq"
			raycast.target_position = Vector2(-30, 0) # Rayo a la izquierda
	else:
		if dir.y > 0:
			anim_actual = "caminar_abajo"
			raycast.target_position = Vector2(0, 30) # Rayo hacia abajo
		else:
			anim_actual = "caminar_arriba"
			raycast.target_position = Vector2(0, -30) # Rayo hacia arriba
			
	anim_player.play(anim_actual)

func _unhandled_input(event):
	# Si presionamos "Aceptar" (Z, Enter, Espacio, etc.)
	if event.is_action_pressed("ui_accept"):
		if raycast.is_colliding():
			var objeto_tocado = raycast.get_collider()
			# Si el objeto que tocamos tiene la función que creamos antes... ¡A pelear!
			if objeto_tocado.has_method("iniciar_encuentro"):
				# 1. ¡PRIMERO manejamos el input mientras el Jugador sigue vivo!
				get_viewport().set_input_as_handled() 
				# 2. LUEGO disparamos la destrucción del mundo y el cambio de escena
				objeto_tocado.iniciar_encuentro()
