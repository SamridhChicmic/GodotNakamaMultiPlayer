extends Control
class_name NakamaMultiplayer
var session:NakamaSession
var client:NakamaClient
var socket :NakamaSocket
var createdMatch
var multiplayerBridge
static var Players={}
signal OnStartGame()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	client=Nakama.create_client("defaultkey",'127.0.0.1',7350,'http')
	pass

func updateUserInfo(username, displayname, avatarurl="", language="en", location="us", timezone="est"):
	await client.update_account_async(session, username, displayname, avatarurl, language, location, timezone)

func onSocketConnected():
	print("Socket Connected")
	pass

func onSocketClosed():
	print("Socket Closed")
	pass
	
func onSocketReceivedError():
	print("Socket Received Error")
	pass

func onSocketReceivedMatchPresence(presence:NakamaRTAPI.MatchPresenceEvent):
	print("Socket Received Match Presence", presence) 
	pass

func onSocketReceivedMatchState(state:NakamaRTAPI.MatchData):
	print("<====Socket Received Match State===>", state, "<==========Session====>", session)
	pass

func _process(delta: float) -> void:
	pass

func _on_login_button_button_down() -> void:
	session = await client.authenticate_email_async($Panel2/EmailEdit.text, "password")
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	
	socket.connected.connect(onSocketConnected)
	socket.closed.connect(onSocketClosed)
	socket.received_error.connect(onSocketReceivedError)
	socket.received_match_presence.connect(onSocketReceivedMatchPresence)
	socket.received_match_state.connect(onSocketReceivedMatchState)
	
	updateUserInfo($Panel2/EmailEdit.text, $Panel2/EmailEdit.text)
	var account = await client.get_account_async(session)
	print("=====Test>", account)
	$Panel/UserAccountText.text = account.user.username
	$Panel/DisplaynameText.text = account.user.display_name
	
	setupMultiPlayerbridge()

func setupMultiPlayerbridge():
	multiplayerBridge = NakamaMultiplayerBridge.new(socket)
	multiplayerBridge.match_joined.connect(onMatchJoin)
	multiplayerBridge.match_join_error.connect(onMatchJoinError)
	var multiplayer = get_tree().get_multiplayer()
	multiplayer.set_multiplayer_peer(multiplayerBridge.multiplayer_peer)
	multiplayer.peer_connected.connect(onPeerConnected)
	multiplayer.peer_disconnected.connect(onPeerDisconnected)
	print("Multiplayer bridge setup complete")

func onPeerDisconnected(id):
	print('Peer Disconnected, ID:', str(id))
	Players.erase(id)
	print("Remaining Players:", Players)

func onPeerConnected(id):
	print('Peer Connected, ID:', str(id))
	if id==0:
		return
	
	if !Players.has(id):
		print("Old id",id)
		Players[id] = {
			"name" : id,
			"ready" : 0
		}
		
	# Add ourself
	if multiplayer.get_unique_id()==0:
		return
	if !Players.has(multiplayer.get_unique_id()):
		print("new id",multiplayer.get_unique_id())
		Players[multiplayer.get_unique_id()] = {
			"name" : multiplayer.get_unique_id(),
			"ready" : 0
		}
	print("Current Players:", Players)

func onMatchJoinError(error):
	print("Unable to Join Match", error.message)
	pass

func onMatchJoin():
	print("Joined match with ID", multiplayerBridge.match_id)
	pass

func _on_store_data_button_down() -> void:
	var saveGame = {
		"name": "username",
		"items": [
			{"id": 1, "name": "gun", "ammo": 10},
			{"id": 2, "name": "sword", "ammo": 0}
		],
		"level": 10
	}
	var data = JSON.stringify(saveGame)
	var result = await client.write_storage_objects_async(session, [
		NakamaWriteStorageObject.new("saves", "savegame", 1, 1, data, "")
	])
	if result.is_exception():
		print("Error storing data", result)
		return
	print("Store Data Successfully")

func _on_get_data_button_down() -> void:
	var result = await client.read_storage_objects_async(session, [
		NakamaStorageObjectId.new("saves", "savegame", session.user_id)
	])
	if result.is_exception():
		print("Error retrieving data", result)
		return
	print("Retrieved Store Data Successfully", result)

func _on_join_create_button_button_down() -> void:
	multiplayerBridge.join_named_match($Panel4/Match.text)
	print("Attempting to join match", $Panel4/Match.text)

func _on_ping_button_down() -> void:
	sendData.rpc("Hello World")
	pass

@rpc("any_peer")
func sendData(message):
	print("Received message:", message)

func _on_match_making_button_down() -> void:
	var query = "+properties.region:US"
	var stringP = {'region': "US"}
	var ticket = await socket.add_matchmaker_async(query, 2, 4, stringP)  # 2 to 4 players

	if ticket.is_exception():
		print("Failed to match")
		return
	print("Match ticket number:", str(ticket))
	socket.received_matchmaker_matched.connect(onMatchMakerMatched)

func onMatchMakerMatched(match):
	var joinedMatch = await socket.join_matched_async(match)
	createdMatch = joinedMatch
	print("Matchmaker matched successfully", createdMatch)

@rpc("any_peer", "call_local")
func Ready(id):
	Players[id].ready = 1
	print("Player", id, "is ready")
	if multiplayer.is_server():
		var readyPlayers = 0
		for i in Players:
			if Players[i].ready == 1:
				readyPlayers += 1
		print("Ready Players:", readyPlayers, "/", Players.size())
		if readyPlayers == Players.size():
			StartGame.rpc()

@rpc("any_peer", "call_local")
func StartGame():
	OnStartGame.emit()
	print("Game starting")
	hide()

func _on_start_button_down() -> void:
	Ready.rpc(multiplayer.get_unique_id())
	print("Player", multiplayer.get_unique_id(), "ready")
