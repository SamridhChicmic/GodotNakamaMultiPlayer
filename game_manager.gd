extends Node2D
@export var multiplayerScene:PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$UI.OnStartGame.connect(onStartGame)
	pass # Replace with function body.

func onStartGame():
	$MultiplayerScene.add_child(multiplayerScene.instantiate())
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
