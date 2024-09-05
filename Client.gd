extends Control

var session:NakamaSession
var client:NakamaClient
var socket :NakamaSocket
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	client=Nakama.create_client("defaultkey",'127.0.0.1',7350,'http')
	
	pass # Replace with function body.

func updateUserInfo(username,displayname,avatarurl="",language="en",location="us",timezone="est"):
	await client.update_account_async(session,username,displayname,avatarurl,language,location,timezone)
func onSocketConnected():
	print("Socket Connected")
	pass

func onSocketClosed():
	print("Socket Closed")
	pass
	
func onSocketReceivedError():
	print("Socket Recived Error")
	pass

func onSocketReceivedMatchPresence(presence:NakamaRTAPI.MatchPresenceEvent):
	print("Socket Received Match Presence",presence) 
	pass

func onSocketReceivedMatchState(state:NakamaRTAPI.MatchData):
	print("Socket Received Match State",state)
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
	print("=====Test>",account)
	$Panel/UserAccountText.text=account.user.username
	$Panel/DisplaynameText.text=account.user.display_name
	pass # Replace with function body.


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
		print("error",result)
		return
	print("Store Data Successfully")
	pass # Replace with function body.


func _on_get_data_button_down() -> void:
	var result=await client.read_storage_objects_async(session,[
		NakamaStorageObjectId.new("saves","savegame",session.user_id)
	])
	if result.is_exception():
		print("error",result)
		return
	print("Get Store Data Successfully",result)
	pass # Replace with function body.


func _on_join_create_button_button_down() -> void:
	var createdMatch=await socket.create_match_async($Panel4/Match.text) #creatematch automatically join
	if createdMatch.is_exception():
		print("Failed to Create match",createdMatch)
		return
	print("===========Created match===========",createdMatch.match_id)
	pass # Replace with function body.


func _on_ping_button_down() -> void:
	pass # Replace with function body.
