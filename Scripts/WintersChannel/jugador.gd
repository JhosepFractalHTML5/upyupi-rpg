extends CharacterBody2D

@export var speed: float = 200.0

# @onready carga el nodo justo cuando el personaje aparece en pantalla
@onready var interaction_ray = $RayCast2D 

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	# Si el personaje se está moviendo, actualizamos la dirección del rayo
	if direction != Vector2.ZERO:
		# direction.normalized() nos da un vector puro de dirección, lo multiplicamos por 50 píxeles de alcance
		interaction_ray.target_position = direction.normalized() * 50

# Esta función detecta cuando presionas un botón
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"): # 'ui_accept' es la tecla Enter o Espacio por defecto
		_try_interact()

func _try_interact():
	# Primero, revisamos si el rayo está chocando con algo
	if interaction_ray.is_colliding():
		# Obtenemos el objeto exacto con el que chocó
		var target = interaction_ray.get_collider()
		
		# Revisamos si ese objeto tiene la capacidad de interactuar
		if target.has_method("interact"):
			target.interact()
