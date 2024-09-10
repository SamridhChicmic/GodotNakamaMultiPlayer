extends Node2D
@export var playerScene : PackedScene

var spawnpoints
# Called when the node enters the scene tree for the first time.
func _ready():
	spawnpoints = get_tree().get_nodes_in_group("spawnpoint")
	var index = 0
	var keys = NakamaMultiplayer.Players.keys()
	keys.sort()
	print("Players==>",NakamaMultiplayer.Players)
	print("KeySorted=====",keys,spawnpoints)
	for i in keys:
		var instancedPlayer = playerScene.instantiate()
		instancedPlayer.name = str(NakamaMultiplayer.Players[i].name)
		
		add_child(instancedPlayer)
		print("Index",index,"===>>",i,"====>",keys,"====>",spawnpoints)
		instancedPlayer.global_position = spawnpoints[index].global_position
		
		index += 1
	#
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
