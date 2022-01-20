extends Camera2D

var targetPosition = Vector2.ZERO

export(Color, RGB) var backgroundColor
export(OpenSimplexNoise) var shakeNoise

var xNoiseSampleVector = Vector2.RIGHT
var yNoiseSampleVector = Vector2.DOWN
var xnoiseSamplePosition = Vector2.ZERO
var ynoiseSamplePosition = Vector2.ZERO
var noiseSampleTravelRate = 500
var maxShakeOffset = 18
var currentShakePercentage = 0
var shakeDecay = 3

func _ready():
	VisualServer.set_default_clear_color(backgroundColor)
	


func _process(delta):
	aquire_target_position()
	
	global_position = lerp(targetPosition, global_position, pow(2,-15* delta))	
	
	
	if (currentShakePercentage > 0 ):
		xnoiseSamplePosition += xNoiseSampleVector * noiseSampleTravelRate * delta
		ynoiseSamplePosition += yNoiseSampleVector * noiseSampleTravelRate * delta		
		var xSample = shakeNoise.get_noise_2d(xnoiseSamplePosition.x, xnoiseSamplePosition.y)
		var ySample = shakeNoise.get_noise_2d(ynoiseSamplePosition.x, ynoiseSamplePosition.y)
		
		var calculatedOffset = Vector2(xSample, ySample) * maxShakeOffset * pow(currentShakePercentage, 2)
		offset = calculatedOffset
	
		currentShakePercentage = clamp(currentShakePercentage - shakeDecay * delta, 0, 1)
		
func apply_shake(percentage):
	currentShakePercentage = clamp(currentShakePercentage + percentage, 0, 1)

func aquire_target_position():
	var aquired = get_target_position_from_node_group("player")
	if (!aquired):
		get_target_position_from_node_group("player_death")
		
func get_target_position_from_node_group(groupName):
	var nodes = get_tree().get_nodes_in_group(groupName)
	if (nodes.size() > 0):
		var node = nodes[0]
		targetPosition = node.global_position
		return true
	return false
