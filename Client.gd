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
	
	pass # Replace with function body.

func updateUserInfo(username,displayname,avatarurl="",language="en",location="us",timezone="est"):
	await client.update_account_async(session,username,displayname,avatarurl,language,location,timezone)
func onSocketConnected():
	#print("Socket Connected")
	pass

func onSocketClosed():
	#print("Socket Closed")
	pass
	
func onSocketReceivedError():
	#print("Socket Recived Error")
	pass

func onSocketReceivedMatchPresence(presence:NakamaRTAPI.MatchPresenceEvent):
	#print("Socket Received Match Presence",presence) 
	pass

func onSocketReceivedMatchState(state:NakamaRTAPI.MatchData):
	#print("<====Socket Received Match State===>",state,"<==========Session====>",session)
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_login_button_button_down() -> void:
	session=await client.authenticate_email_async($Panel2/EmailEdit.text,"password")
	socket=Nakama.create_socket_from(client)
	await  socket.connect_async(session)
	
	socket.connected.connect(onSocketConnected)
	socket.closed.connect(onSocketClosed)
	socket.received_error.connect(onSocketReceivedError)
	socket.received_match_presence.connect(onSocketReceivedMatchPresence)## Match Exist
	socket.received_match_state.connect(onSocketReceivedMatchState)## Match play end 
	updateUserInfo($Panel2/EmailEdit.text,$Panel2/EmailEdit.text)
	var account = await client.get_account_async(session)
	#print("=====Test>",account)
	$Panel/UserAccountText.text=account.user.username
	$Panel/DisplaynameText.text=account.user.display_name
	
	setupMultiPlayerbridge()
	pass # Replace with function body.

func setupMultiPlayerbridge():
	multiplayerBridge=NakamaMultiplayerBridge.new(socket)
	multiplayerBridge.match_joined.connect(onMatchJoin)
	multiplayerBridge.match_join_error.connect(onMatchJoinError)
	var multiplayer=get_tree().get_multiplayer()
	multiplayer.set_multiplayer_peer(multiplayerBridge.multiplayer_peer)
	multiplayer.peer_connected.connect(onPeerConnected)
	multiplayer.peer_disconnected.connect(onPeerDisconnected)
	pass

func onPeerDisconnected(id):
	#print('peer Disconnected id is:',str(id))
	pass
func onPeerConnected(id):
	#print('peer connected id is:',str(id))
	if !Players.has(id):
		Players[id] = {
			"name" : id,
			"ready" : 0
		}
	#Add OurSelf	
	if !Players.has(multiplayer.get_unique_id()):
		Players[multiplayer.get_unique_id()]= {
			"name" : multiplayer.get_unique_id(),
			"ready" : 0
		}
	#print(Players)
func onMatchJoinError(error):
	#print("Unable to Join Match",error.message)
	pass

func onMatchJoin():
	#print("join match with id",multiplayerBridge.match_id)
	pass
func _on_store_data_button_down() -> void:
	var saveGame={
		"name":"username",
		"items":[{
			"id":1,
			"name":"gun",
			"ammo":10
		},
		{
			"id":2,
			"name":"sward",
			"ammo":0
		}
		],
		"level":10
	}
	var data=JSON.stringify(saveGame)
	var result=await client.write_storage_objects_async(session,[
		NakamaWriteStorageObject.new("saves","savesgame",1,1,data,"")
	])
	if result.is_exception():
		#print("error",result)
		return
	#print("Store Data Successfully")
	pass # Replace with function body.


func _on_get_data_button_down() -> void:
	var result=await client.read_storage_objects_async(session,[
		NakamaStorageObjectId.new("saves","savegame",session.user_id)
	])
	if result.is_exception():
		#print("error",result)
		return
	#print("Get Store Data Successfully",result)
	pass # Replace with function body.


func _on_join_create_button_button_down() -> void:
	multiplayerBridge.join_named_match($Panel4/Match.text)
	#createdMatch=await socket.create_match_async($Panel4/Match.text) #creatematch automatically join
	#if createdMatch.is_exception():
		#print("Failed to Create match",createdMatch)
		#return
	#print("===========Created match===========",createdMatch.match_id)
	pass # Replace with function body.


func _on_ping_button_down() -> void:
	sendData.rpc("hello World")
	#var data={"hello":"world"}
	#socket.send_match_state_async(createdMatch.match_id,1,JSON.stringify(data))
	#pass # Replace with function body.

@rpc("any_peer")
func sendData(message):
	pass
	#print(message)


func _on_match_making_button_down() -> void:
	#var query="+properties.region:US +properties.rank:>4 +properties.rank:<10"
	var query="+properties.region:US"
	var stringP={'region':"US"}
	#var numberP={'rank':6}
	var ticket=await socket.add_matchmaker_async(query,2,2,stringP)
	
	if ticket.is_exception():
		#print("Failed to match")
		return
	#print("match ticket number ",str(ticket))
	socket.received_matchmaker_matched.connect(onMatchMakerMatched)

func onMatchMakerMatched(match):
	var joinedMatch=await socket.join_matched_async(match)
	createdMatch=joinedMatch

@rpc("any_peer", "call_local")
func Ready(id):
	Players[id].ready = 1
	if multiplayer.is_server():
		var readyPlayers = 0
		for i in Players:
			if Players[i].ready == 1:
				readyPlayers += 1
		if readyPlayers == Players.size():
			StartGame.rpc()

@rpc("any_peer", "call_local")
func StartGame():
	OnStartGame.emit()
	hide()
	pass

func _on_start_button_down() -> void:
	Ready.rpc(multiplayer.get_unique_id())
	pass # Replace with function body.
