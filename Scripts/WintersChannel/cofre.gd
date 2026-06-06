extends StaticBody2D

# Exportamos esta variable para poder cambiar el texto fácilmente desde el Inspector
@export var mensaje: String = "¡Has encontrado una poción oculta!"

func interact():
	# Por ahora, imprimimos el mensaje en la consola de Godot (abajo)
	print("Interacción detectada: ", mensaje)
	
	# Aquí en el futuro puedes abrir un cuadro de diálogo, sumar ítems a tu inventario, etc.
