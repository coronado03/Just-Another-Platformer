extends KinematicBody2D
 
signal died
var playerDeathScene = preload('res://scenes/PlayerDeath.tscn')
var footstetpParticles = preload("res://scenes/FootstepParticles.tscn")

enum State {NORMAL, DASHING, INPUT_DISABLED}

export(int, LAYERS_2D_PHYSICS) var dashHazardMask

var gravity = 1000
var velocity = Vector2.ZERO
var maxHorizontalSpeed = 100
var maxDashSpeed = 500
var minDashSpeed = 200
var jumpSpeed = 300
var horizontalAcceleration = 2000
var jumpTerminationMultiplier = 4
var hasDoubleJump = false
var hasDash = false
var currentState = State.NORMAL
var isStateNew = true
var isDying = false

var defaultHazardMask = 0

func _ready():
	$HazardArea.connect("area_entered", self, "on_hazard_area_entered")
	$AnimatedSprite.connect("frame_changed", self, "on_animated_sprite_frame_changed")
	defaultHazardMask = $HazardArea.collision_mask 



func _process(delta):
	match currentState:
		State.NORMAL:
			process_normal(delta)
		State.DASHING:
			process_dash(delta)
		State.INPUT_DISABLED:
			process_input_disabled(delta)
	isStateNew = false
	
	
func change_state(newState):
	currentState = newState
	isStateNew = true
	
	
func process_dash(delta):
	if (isStateNew):
		$DashAudioPlayer.play()
		$DashParticles.emitting = true
		$"/root/Helpers".apply_camera_shake(.75)
		$DashArea/CollisionShape2D.disabled = false
		$AnimatedSprite.play("jump")
		$HazardArea.collision_mask = dashHazardMask
		var moveVector = get_movement_vector()
		var velocityMod = 1
		if(moveVector.x != 0):
			velocityMod = sign(moveVector.x)	
		else:
			velocityMod = 1 if $AnimatedSprite.flip_h else -1
		
		velocity = Vector2(maxDashSpeed * velocityMod, 0)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	velocity. x = lerp(0, velocity.x, pow(2,-8 * delta))
	
	if (abs(velocity.x) < minDashSpeed):
		call_deferred("change_state", State.NORMAL)
	
	
func process_input_disabled(delta):
	velocity.x = lerp(0, velocity.x, pow(2, -25 * delta))
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	


func process_normal(delta):
	
	if (isStateNew):
		$DashParticles.emitting = false
		$DashArea/CollisionShape2D.disabled = true
		$HazardArea.collision_mask = defaultHazardMask
	
	var moveVector = get_movement_vector()
	
	if (is_on_floor()):
		hasDoubleJump = true
		hasDash = true
	
	if (moveVector.y < 0 && (is_on_floor() || !$CoyoteTimer.is_stopped() || hasDoubleJump)):
		velocity.y = moveVector.y * jumpSpeed
		
		
		if (!is_on_floor() && $CoyoteTimer.is_stopped()):
			$"/root/Helpers".apply_camera_shake(.75)
			hasDoubleJump = false
			
		$CoyoteTimer.stop()
			
	velocity.x += moveVector.x * horizontalAcceleration * delta
	if (moveVector.x == 0):
		velocity.x = lerp(0, velocity.x, pow(2, -25 * delta))
	
	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)
		
	
	if (velocity.y < 0 && !Input.is_action_pressed("jump")):
		velocity.y += gravity * jumpTerminationMultiplier * delta
	else:
		velocity.y += gravity * delta
	
	var wasOnfloor = is_on_floor() 
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if (wasOnfloor && !is_on_floor()):
		$CoyoteTimer.start()
		
		
	if (!wasOnfloor and is_on_floor() and !isStateNew):
		spawn_footsteps(1.5)
		
	
	if (hasDash and Input.is_action_just_pressed("dash")):
		call_deferred("change_state", State.DASHING)
		hasDash = false
		
	update_animation()
	

func get_movement_vector():
	var moveVector = Vector2.ZERO
	moveVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveVector.y = -1 if Input.is_action_just_pressed("jump") else 0
	return moveVector
	
func update_animation():
	var moveVec = get_movement_vector()
	
	if (!is_on_floor()):
		$AnimatedSprite.play("jump")
	elif (moveVec.x != 0):
		$AnimatedSprite.play("run")
	elif (moveVec.x == 0):
		$AnimatedSprite.play("idle")
	
	if (moveVec.x != 0 ):
		$AnimatedSprite.flip_h = false if moveVec.x < 0 else true

func kill():
	if (isDying):
		return
	isDying = true
	var playerDeathInstance = playerDeathScene.instance()
	playerDeathInstance.velocity = velocity
	get_parent().add_child_below_node(self, playerDeathInstance)
	playerDeathInstance.global_position = global_position

	emit_signal("died")	
	
func spawn_footsteps(scale = 1):
		var footstep = footstetpParticles.instance()
		get_parent().add_child(footstep)
		footstep.scale = Vector2.ONE * scale
		footstep.global_position = global_position
		$FootStepAudioPlayer.play()

func disable_player_input():
	change_state(State.INPUT_DISABLED)
	
func on_hazard_area_entered(area2d):
	$"/root/Helpers".apply_camera_shake(1)
	call_deferred("kill")

func on_animated_sprite_frame_changed():
	if ($AnimatedSprite.animation == 'run' and $AnimatedSprite.frame == 0):
		spawn_footsteps()
		
