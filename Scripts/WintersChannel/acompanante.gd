extends CharacterBody2D

@onready var sprite = $SpriteLider
@onready var anim_player = $AnimadorLider

var lider: Node2D = null
# ¡Este es el hilo mágico! Aumenta este número para que camine más lejos.
var retraso: int = 25 

func _ready():
	# --- TRUCO DE CAPAS ---
	y_sort_enabled = true 
	
	if GlobalGame.party_actual.size() > 1:
		var char_acomp = GlobalGame.party_actual[1]
		if char_acomp.textura_sprite != null:
			sprite.texture = char_acomp.textura_sprite
			sprite.frame = 0

func _physics_process(_delta):
	if lider and lider.historial.size() > retraso:
		var datos_pasados = lider.historial[retraso]
		global_position = datos_pasados.pos
		
		# Si el líder se ha detenido, el seguidor también detiene su animación
		if lider.velocity == Vector2.ZERO:
			anim_player.stop()
		else:
			# Si el líder avanza, reproducimos la animación del pasado
			anim_player.play(datos_pasados.anim)
