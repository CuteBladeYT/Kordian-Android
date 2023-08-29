extends Node

#const SERVER_URL = "https://kordianapi.unitedcatdom.repl.co"
const WS_URL = "wss://kordianapi.unitedcatdom.repl.co/"

var ws = WebSocketClient.new()

var REQS: Node
var reconTimeout: Timer

var autologin: bool = Tweaks.settings["app"]["auto_login"]
var loginform: Control
var messages: Control
    
# ==============
# SHA256 HASHING
func sha256(text: String) -> String:
    return text.sha256_text()

# =======================
# API ENDPOINTS VARIALBES
const API_ACCOUNTS = "account/"
const API_ACCOUNTS_REGISTER = API_ACCOUNTS + "register"
const API_ACCOUNTS_LOGIN = API_ACCOUNTS + "login"
const API_ACCOUNTS_DELETE = API_ACCOUNTS + "delete"
const API_ACCOUNTS_VERIFY_EMAIL = API_ACCOUNTS + "verify_email"
const API_ACCOUNTS_GET_INFO = API_ACCOUNTS + "get_account_data"
const API_ACCOUNTS_GET_UID = API_ACCOUNTS + "fetch_uid"

const API_ACCOUNTS_UPDATE = API_ACCOUNTS + "update/"
const API_ACCOUNTS_UPDATE_USERNAME = API_ACCOUNTS_UPDATE + "username"
const API_ACCOUNTS_UPDATE_EMAIL = API_ACCOUNTS_UPDATE + "email"
const API_ACCOUNTS_UPDATE_PASSWORD = API_ACCOUNTS_UPDATE + "password"
const API_ACCOUNTS_UPDATE_PICTURE_URL = API_ACCOUNTS_UPDATE + "picture_url"
const API_ACCOUNTS_UPDATE_EMAIL_PRIVACY = API_ACCOUNTS_UPDATE + "email_privacy"

const API_MESSAGES = "message/"
const API_MESSAGES_CONNECT_ROOM = API_MESSAGES + "connect"
const API_MESSAGES_SEND_MESSAGE = API_MESSAGES + "send_message"
const API_MESSAGES_FETCH_MESSAGES = API_MESSAGES + "fetch_messages"

# ============
# CALL TARGETS
var callmap = {
    API_ACCOUNTS_REGISTER: [],
    API_ACCOUNTS_LOGIN: [],
    API_ACCOUNTS_DELETE: [],
    API_ACCOUNTS_VERIFY_EMAIL: [],
    API_ACCOUNTS_GET_INFO: [],
    API_ACCOUNTS_GET_UID: [],
    
    API_ACCOUNTS_UPDATE_USERNAME: [],
    API_ACCOUNTS_UPDATE_EMAIL: [],
    API_ACCOUNTS_UPDATE_PASSWORD: [],
    API_ACCOUNTS_UPDATE_PICTURE_URL: [],
    API_ACCOUNTS_UPDATE_EMAIL_PRIVACY: [],
    
    API_MESSAGES_CONNECT_ROOM: [],
    API_MESSAGES_SEND_MESSAGE: [],
    API_MESSAGES_FETCH_MESSAGES: [],
}

# ===============================
# CONNECT
func _ready() -> void:
    ws.connect("connection_closed", self, "ws_closed")
    ws.connect("connection_error", self, "ws_closed")
    ws.connect("connection_established", self, "ws_connected")
    ws.connect("data_received", self, "ws_data")
    
    api_reconnect()

func api_recon(err) -> void:
    if err != OK:
        Notification.add_notif("%s. %s" % [tr("api_connection_stopped"), tr("api_connection_retrying")], Color("f38b8b"))
        reconTimeout.start()
    else:
        Notification.add_notif(tr("api_connection_estabilished"), Color("a6e3a1"))
        reconTimeout.stop()

func api_reconnect() -> void:
    var err = ws.connect_to_url(WS_URL)
    if reconTimeout:
        print(reconTimeout.is_stopped())

func _process(delta: float) -> void:
    ws.poll()
    
func ws_closed(clean: bool = false) -> void:
    printerr(tr("api_connection_stopped"))
    print("Clean? %s" % [clean])
    api_recon(1)
    return

func ws_connected(protocol = "") -> void:
    print("%s %s" % [tr("api_connection_estabilished"), str(protocol)])
    api_recon(0)
    if autologin == true:
        if loginform:
            loginform.call("_on_login_pressed")

func CreateSendDict() -> Dictionary:
    return {"request":""}

func get_image_extension_from_url(url: String):
    if url is String:
        if url.find(".") > 0:
            var s = url.split(".")
            var ext = s[s.size()-1]
            return ext
    return null

func stringify(dict: Dictionary):
    if dict is Dictionary:
        return JSON.print(dict)
    return dict
func jsonify(string: String):
    if string is String:
        return JSON.parse(string).result
    return string

# SEND WSRQ
func SEND(data: String) -> int:
    var err = ws.get_peer(1).put_packet(str(data).to_utf8())
    if err != OK:
        printerr("Cannot send packet to peer, ERR::%s" % [err])
    return err

# ================
# ON DATA RECEIVED
func ws_data() -> void:
    # wsr (websocket response)
    var wsr = jsonify(ws.get_peer(1).get_packet().get_string_from_utf8())
    
    var rtype = wsr["request"]
    var data = wsr["data"]
    
    var callable := true
    
    if data is String: 
        if data.begins_with("ERR::"):
            callable = false
            printerr("Error loading data, %s" % [data])
            return
            
    elif data is Dictionary:
        var type = data.get("type")
        if type:
            callable = false
            # on user room join
            if type == "notif":
                Notification.add_notif(data["message"])
                
            # when message is sent
            if type == "message":
                #var author = data["sender"]
                #var content = data["content"]
                #var timestamp = data["timestamp"]
                data["content"] = data["content"].percent_decode()
                var ctime = data["name"]
                messages.call("APPEND_FETCH_MESSAGES", {
                    ctime: data
                })
    
    if callable == true:
        var call = callmap[rtype]
        var arg = null
        if call.size() > 2:
            arg = call[2]
        
        if arg:
            call[0].call(call[1], data, arg)
        else:
            call[0].call(call[1], data)

# ===========================
# REMOVE UNUSED REQUEST NODE
#func _REMOVE_REQUEST_NODE(req: HTTPRequest) -> void:
#    if REQS.has_node(req.name):
#        REQS.get_node(req.name).queue_free()
#        REQS.remove_child(req)
        
# CREATE BASE REQUEST
#func _CREATE_REQUEST(nodename: String) -> HTTPRequest:
#    var rq := HTTPRequest.new()
#    rq.name = sha256(nodename)
#    REQS.add_child(rq)
#    rq.connect("request_completed", self, "_REMOVE_REQUEST_NODE", [rq])
#    return rq

# =================================================
# AN ACTUAL API SECTION THAT THE CLIENT WILL USE TO
# COMMUNICATE WITH SERVER

# TEST SERVER AVAILABILITY
#func PING_SERVER(target: Node, method: String) -> void:
#    var rq := _CREATE_REQUEST("SERVERPING")
#    rq.connect("request_completed", target, method)
#    rq.request(SERVER_URL)

# REGISTER ACCOUNT
func REGISTER_ACCOUNT(email: String, password: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_REGISTER
    data["email"] = email.percent_encode()
    data["password"] = password.percent_encode()
    data = stringify(data)
    var err = SEND(data)
    return
    
# LOGIN TO ACCOUNT
func LOGIN_ACCOUNT(email: String, password: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_LOGIN
    data["email"] = email.percent_encode()
    data["password"] = password.percent_encode()
    data = stringify(data)
    var err = SEND(data)
    return

# VERIFY EMAIL
func VERIFY_EMAIL(token: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_VERIFY_EMAIL
    data["token"] = token
    data = stringify(data)
    var err = SEND(data)
    return

# GET ACCOUNT UID
func GET_ACCOUNT_UID(token: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_GET_UID
    data["token"] = token
    data = stringify(data)
    var err = SEND(data)
    return
    
# GET ACCOUNT DATA
func GET_ACCOUNT_DATA(uid: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_GET_INFO
    data["uid"] = uid
    data = stringify(data)
    var err = SEND(data)
    return

# GET USER PROFILE PIC
func GET_USER_PROFILE_PICTURE(picture_url: String, uid: String, kwargs: Array, target: Node, method: String) -> void:
    if not kwargs: kwargs = []
    kwargs.push_front(uid)
    var rq := HTTPRequest.new()
    REQS.add_child(rq)
    var imgext = get_image_extension_from_url(picture_url)
    rq.name = "DN_GET_PROFILE_PIC"
    rq.download_file = Tweaks.PATHS+ "pfp/%s.%s" % [uid, imgext]
    rq.connect("request_completed", self, "_GET_USR_PFP_PT1", [uid, imgext, kwargs, target, method, rq])
    rq.request(picture_url)
    return

# func _GET_USR_PFP_PT1(___d2, ___d0, ___d1, rqbody, uid: String, target: Node, method: String, kwargs := []) -> void:
#     var rq := _CREATE_REQUEST("GETPFPTEXTURE")
#     var pfp = JSON.parse(rqbody.get_string_from_utf8()).result["photo_url"]
#     var imgext = pfp.split(".")[pfp.split(".").size()-1]
#     rq.connect("request_completed", self, "_GET_USR_PFP_PT2", [uid, target, method, imgext, kwargs])
#     rq.download_file = Tweaks.PATHS+ "pfp/%s.%s" % [uid, imgext]
#     rq.request(pfp)
#     return

func _GET_USR_PFP_PT1(___d2, ___d0, ___d1, ___d3, uid: String, imgext: String, kwargs: Array, target: Node, method: String, rq: HTTPRequest) -> void:
    rq.queue_free()
    var texture = LOAD_TEXTURE_FROM_IMAGE("pfp/%s.%s" % [uid, imgext])
    target.call(method, texture, kwargs)
    return

func LOAD_TEXTURE_FROM_IMAGE(path: String):
    var image = Image.new()
    var err = image.load(Tweaks.PATHS+ path)
    if err != OK:
        printerr("Unable to load image, ERR::%s" % [err])
        return
    var texture = ImageTexture.new()
    texture.create_from_image(image, 0)
    return texture

# UPDATE USER NAME
func UPDATE_USER_NAME(token: String, username: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_UPDATE_USERNAME
    data["token"] = token
    data["name"] = username.percent_encode()
    data = stringify(data)
    var err = SEND(data)
    return
    
# UPDATE USER PROFILE PICTURE URL
func UPDATE_USER_PICTURE_URL(token: String, picture_url: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_UPDATE_PICTURE_URL
    data["token"] = token
    data["url"] = picture_url.percent_encode()
    data = stringify(data)
    var err = SEND(data)
    return

# UPDATE PASSWORD
func UPDATE_USER_PASSWORD(token: String, password: String) -> void:
    var data = CreateSendDict()
    data["request"] = API_ACCOUNTS_UPDATE_PICTURE_URL
    data["token"] = token
    data["password"] = password.percent_encode()
    data = stringify(data)
    var err = SEND(data)
    return

# # =========
# # MESSAGING

# CONNECT TO ROOM
func CONNECT_TO_ROOM(token: String, room_id: int) -> void:
    var data = CreateSendDict()
    data["request"] = API_MESSAGES_CONNECT_ROOM
    data["token"] = token
    data["room"] = room_id
    data = stringify(data)
    var err = SEND(data)
    return

# FETCH MESSAGES
func FETCH_ROOM_MESSAGES(room_id: int, limit: int) -> void:
    var data = CreateSendDict()
    data["request"] = API_MESSAGES_FETCH_MESSAGES
    data["room"] = room_id
    data["limit"] = limit
    data = stringify(data)
    var err = SEND(data)
    return

# SEND MESSAGE
func ROOM_SEND_MESSAGE(token: String, room_id: int, content: String) -> void:
    if content.length() > 0:
        var data = CreateSendDict()
        data["request"] = API_MESSAGES_SEND_MESSAGE
        data["token"] = token
        data["room"] = room_id
        data["content"] = content.percent_encode()
        data = stringify(data)
        var err = SEND(data)
