extends CanvasLayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _unhandled_input(event):
	if (event.is_action_pressed("click")):
		$AnimationPlayer.play("click")

func _process(delta):
	$Sprite.global_position = $Sprite.get_global_mouse_position()
	if (Input.is_action_just_pressed("click")):
		$AnimationPlayer.play("click")
	
	
