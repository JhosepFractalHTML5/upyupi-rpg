extends CharacterBody2D

@onready var sprite = $SpriteLider
@onready var anim_player = $AnimadorLider

var lider: Node2D = null
var retraso: int = 25
var identidad: CharacterStats = null # Aquí recibimos nuestro "DNI" (Romn, Massi, etc)
var nombre_personaje: String = "" # Guardamos el nombre para saber quién soy

# --- VARIABLES DE CEREBRO ---
@export var modo_esperar_cinematicas: bool = false 
var en_cinematica: bool = false 
var reconectando: bool = false  
var velocidad_caminar: float = 120.0

func _ready():
	y_sort_enabled = true
	
	# Si Jhosep nos dio una identidad al instanciarnos, nos ponemos ese traje
	if identidad != null:
		nombre_personaje = identidad.nombre # Ej: "Romn" o "Massi"
		
		if identidad.textura_sprite != null:
			sprite.texture = identidad.textura_sprite
			sprite.frame = 0

func _physics_process(delta):
	if not lider: return
	
	if en_cinematica: return
	
	var lider_ocupado = lider.get("en_cinematica") or GestorDialogos.dialogo_activo
	
	# 2. ESPERAR
	if lider_ocupado and modo_esperar_cinematicas:
		reconectando = true 
		anim_player.stop() # Se queda quietecito esperando
		return 
		
	# 3. MODO "ALCANZAR" (Opción 2)
	if reconectando:
		if lider.historial.size() > retraso:
			var punto_objetivo = lider.historial[retraso].pos
			
			if global_position.distance_to(punto_objetivo) > 2.0:
				# Calculamos hacia dónde tiene que mirar para alcanzar a Jhosep
				var direccion = global_position.direction_to(punto_objetivo)
				global_position = global_position.move_toward(punto_objetivo, velocidad_caminar * delta)
				
				# ¡REPRODUCIMOS ANIMACIÓN MIENTRAS CORRE!
				_animar_por_direccion(direccion)
				return
			else:
				reconectando = false
				
	# 4. MODO NORMAL (Siguiendo el historial)
	if lider.historial.size() > retraso:
		var datos_pasados = lider.historial[retraso]
		
		# Verificamos si realmente se está moviendo hacia ese punto del pasado
		if global_position != datos_pasados.pos:
			global_position = datos_pasados.pos
			
			# ¡REPRODUCIMOS LA ANIMACIÓN GRABADA DE JHOSEP!
			if datos_pasados.get("anim", "") != "":
				anim_player.play(datos_pasados.anim)
		else:
			# Si Jhosep está quieto, nosotros también
			anim_player.stop()

# --- NUEVA FUNCIÓN DE AYUDA ---
# Le enseña al acompañante a adivinar su propia animación cuando camina solo
func _animar_por_direccion(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim_player.play("caminar_der")
		else:
			anim_player.play("caminar_izq")
	else:
		if dir.y > 0:
			anim_player.play("caminar_abajo")
		else:
			anim_player.play("caminar_arriba")
