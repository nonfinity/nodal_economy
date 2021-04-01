extends Camera2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var move_speed: float = 200.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var adjvec: Vector2 = calculate_input_vector(delta)
	
	position += adjvec
	pass

func calculate_input_vector(delta) -> Vector2:
	var out: Vector2 = Vector2.ZERO
	
	out.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	out.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	out.x *= move_speed * delta
	out.y *= move_speed * delta
	
	return out
