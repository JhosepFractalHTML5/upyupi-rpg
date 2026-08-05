extends CharacterBody2D
class_name JugadorOverworld

const VELOCIDAD = 150.0

@onready var sprite = $SpriteLider
@onready var anim_player = $AnimadorLider
@onready var raycast = $RayCast2D

# --- SISTEMA DE ACOMPAÑANTE ---
var historial: Array[Dictionary] = []
var max_historial: int = 150 # ¡ACTUALIZADO A 150! Así caben 4 personajes sin problemas.
var anim_actual: String = ""
var en_cinematica: bool = false
var ultima_pos_grabada: Vector2 = Vector2.ZERO

var AcompananteEscena = preload("res://Escenas/Almas/Test/acompanante.tscn") 
var mis_acompanantes: Dictionary = {}

func _ready():
	get_parent().y_sort_enabled = true
	y_sort_enabled = true
	for i in range(max_historial):
		historial.append({"pos": global_position, "anim": ""})
	
	# 1. ADAPTAR EL JUGADOR AL LÍDER (Índice 0)
	if GlobalGame.party_actual.size() > 0:
		var lider_stats = GlobalGame.party_actual[0]
		if lider_stats.textura_sprite != null:
			sprite.texture = lider_stats.textura_sprite
			sprite.frame = 0
			
	# 2. GENERAR AL RESTO DE LA PARTY AUTOMÁTICAMENTE
	_generar_party() 
	
	# 3. LA MAGIA DEL REGRESO AL OVERWORLD
	if GlobalGame.volver_de_batalla:
		global_position = GlobalGame.posicion_jugador_mapa
		GlobalGame.volver_de_batalla = false 
		print("[SISTEMA] Jugador teletransportado a su posición previa: ", global_position)

func _physics_process(delta):
	# --- LA CAJA NEGRA (¡Ahora solo graba una vez!) ---
	if global_position != ultima_pos_grabada:
		historial.push_front({"pos": global_position, "anim": anim_actual})
		if historial.size() > max_historial:
			historial.pop_back()
		ultima_pos_grabada = global_position
		
	# --- SEGURO DE CINEMÁTICA ---
	if en_cinematica or GestorDialogos.dialogo_activo:
		return 
		
	var direccion = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	if direccion != Vector2.ZERO:
		velocity = direccion * VELOCIDAD
		_actualizar_animacion(direccion)
		
		# --- DRENAJE DE PT ---
		GlobalGame.registrar_movimiento(velocity.length() * delta)
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

func _generar_party():
	# Si solo está Jhosep (tamaño 1), no hacemos nada
	if GlobalGame.party_actual.size() <= 1:
		return
		
	var retraso_base = 25 # El espacio entre cada personaje
	
	# Bucle que empieza en 1 (saltando al prota) hasta el final de la party
	for i in range(1, GlobalGame.party_actual.size()):
		var stats_del_amigo = GlobalGame.party_actual[i]
		var nuevo_acompanante = AcompananteEscena.instantiate()
		# 1. Le decimos quién es su líder y a qué distancia debe ir
		nuevo_acompanante.lider = self
		nuevo_acompanante.retraso = retraso_base * i # Amigo 1 = 25, Amigo 2 = 50, Amigo 3 = 75
		nuevo_acompanante.global_position = self.global_position
		# 2. Le inyectamos su identidad (su recurso .tres)
		nuevo_acompanante.identidad = stats_del_amigo
		# 3. Lo ponemos en el mundo (al mismo nivel que Jhosep)
		get_parent().call_deferred("add_child", nuevo_acompanante)
		# 4. Lo guardamos en la agenda para usarlo en cinemáticas
		mis_acompanantes[stats_del_amigo.nombre] = nuevo_acompanante

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
