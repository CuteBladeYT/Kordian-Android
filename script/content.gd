extends Control

var cache := ConfigFile.new()
var CACHE_PATH: String = Tweaks.PATHS+ "cache.ini"

var ROOMID: int = -1
var CONNECTED: bool = false

const MESSAGE_HEIGHT = 144
const MESSAGE_CONTENT_LINE_HEIGHT = 35

onready var slider_panel: Control = self.get_parent().get_node("slider_panel")

var MSG_N_CALL: Array = []

func _ready() -> void:
    api.callmap[api.API_ACCOUNTS_GET_INFO] = [self, "UPDATE_MESSAGE_SENDER_NAME"]
    api.messages = self
    
    cache.clear()
    cache.load(CACHE_PATH)

func _process(delta: float) -> void:
    if Tweaks.CHAT_DEF_HEIGHT > 0:
        var v_keyboard_height = OS.get_virtual_keyboard_height()# if Tweaks.IS_ANDROID == true else 755
        var s = Tweaks.settings
        if v_keyboard_height > 0:
            var scale = s["appearance"]["ui_scale"]
            var hh = s["appearance"]["header_height"]
            var ks = s["appearance"]["keyboard_shrink"]
            #var size = -int((v_keyboard_height / scale) + (s["appearance"]["header_height"] / scale) + (s["appearance"]["header_height"]))
            #var size = -int((v_keyboard_height / scale) + (hh / scale) - 16)
            var size = -ks# + v_keyboard_height
            
            #self.rect_size.y = int(Tweaks.CHAT_DEF_HEIGHT - (v_keyboard_height * scale))
            self.margin_bottom = size
            
        else:
            #self.rect_size.y = Tweaks.CHAT_DEF_HEIGHT
            self.margin_bottom = 0
        
func CONNECT_TO_ROOM() -> void:
    if User.email_verified == true:
        ROOMID = get_parent().get_node("slider_panel/roomcfg/scroll/container/roomid").value
        api.callmap[api.API_MESSAGES_CONNECT_ROOM] = [self, "ROOM_CONNECT_RESPONSE"]
        api.CONNECT_TO_ROOM(User.token, ROOMID)
    else:
        Notification.add_notif(tr("rooms_error_unverified_email"))

func ROOM_CONNECT_RESPONSE(res: String) -> void:
    if int(res) == 0:
        Notification.add_notif("%s %s" % [tr("rooms_connected_notif"), str(ROOMID)], Colors.theme["colors"]["activated"])
        CONNECTED = true
        api.callmap[api.API_MESSAGES_FETCH_MESSAGES] = [self, "APPEND_FETCH_MESSAGES", true] # idx:2 is a "clear" parameter
        api.FETCH_ROOM_MESSAGES(ROOMID, 100)
        slider_panel.slider_visibility(false)
    else:
        if res.begins_with("ERR:: Email unverified"):
            Notification.add_notif(tr("rooms_error_unverified_email"))
        CONNECTED = false
        ROOMID = -1
        Notification.add_notif(res, Colors.theme["colors"]["disabled"])
    return

func APPEND_FETCH_MESSAGES(messages, clear: bool = false) -> void:
    if messages == null:
        printerr(messages)
        return
    
    if clear == true:
        for msg in $messages/scroll/list.get_children():
            msg.queue_free()
    
    if messages is Dictionary:
        for msgkey in messages.keys():
            var msg = messages[msgkey]
            var content = str(msg["content"]).percent_decode()
            var suid = str(msg["sender"]).percent_decode()
            var timestamp = str(msg["timestamp"])
            var roomid = str(msg["room"]).percent_decode()
            
            _CREATE_MESSAGE_NODE(content, suid, timestamp)
            
            if cache.has_section_key("messages", roomid):
                var msgs: Dictionary = cache.get_value("messages", roomid)
                msgs[msgkey] = msg
                cache.set_value("messages", roomid, msgs)
            else:
                cache.set_value("messages", roomid, {msgkey:msg})
        
        cache.save(CACHE_PATH)
    
    return


func SEND_MESSAGE() -> void:
    if CONNECTED == true:
        var msg = $input/msg.text
        $input/send.disabled = true
        api.callmap[api.API_MESSAGES_SEND_MESSAGE] = [self, "MESSAGE_SEND_RESPONSE"]
        api.ROOM_SEND_MESSAGE(User.token, ROOMID, msg)
        $input/msg.text = ""
        $input/msg.grab_focus()
        
func MESSAGE_SEND_RESPONSE(res) -> void:
    if res != "0":
        printerr(res)
    $input/send.disabled = false
    return

func _CREATE_MESSAGE_NODE(content: String, sender_uid: String, timestamp: String) -> void:
    
    var datetime = Tweaks.get_time_dict(int(timestamp))
    
    var msg = $messages/msg.duplicate()
    
    msg.name = str(timestamp.replace(".","_"))
    var con = msg.get_node("vbox/content")
    var date = msg.get_node("vbox/sender/hbox/timestamp/date")
    var time = msg.get_node("vbox/sender/hbox/timestamp/time")
    var sendername = msg.get_node("vbox/sender/hbox/sendername")
    var senderpic = msg.get_node("vbox/sender/senderpic")
    var senderuid = msg.get_node("vbox/sender/uid")
    
    con.text = content
    date.text = "%s.%s.%s" % [datetime["day"], datetime["month"], datetime["year"]]
    time.text = "%s:%s:%s" % [datetime["hour"] + datetime["offset"], datetime["minute"], datetime["second"]]
    senderuid.text = sender_uid
    
    var stackmsg: bool = false
    
    if $messages/scroll/list.get_child_count() > 0:
        var lastmsg: Control = $messages/scroll/list.get_child($messages/scroll/list.get_child_count()-2)
        if lastmsg.get_node("vbox/sender/uid").text == sender_uid:
            stackmsg = true
            msg.get_node("vbox/sender").hide()
    
    if stackmsg == false:
        if cache.has_section_key("users", sender_uid) == true:
            var usrdata = cache.get_value("users", sender_uid)
            sendername.text = usrdata["username"]
            
            var pic = api.LOAD_TEXTURE_FROM_IMAGE(usrdata["picture"])
            if pic:
                senderpic.texture = pic
        else:
            MSG_N_CALL.append(msg.name)
        
            api.callmap[api.API_ACCOUNTS_GET_INFO] = [self, "UPDATE_MESSAGE_SENDER_NAME"]
            api.GET_ACCOUNT_DATA(sender_uid)
    
    msg.visible = true
    
    var sep = HSeparator.new()
    
    $messages/scroll/list.add_child(msg)
    $messages/scroll/list.add_child(sep)
    
    #if stackmsg == true:
    #    sep.hide()
    
    init_sep_timer(msg, sep, stackmsg)

func update_ui() -> void:
    for ei in $messages/scroll/list.get_child_count():
        var e = $messages/scroll/list.get_child(ei)
        if e is Control:
            var sep = $messages/scroll/list.get_child(ei+1)
            #print(e, sep)
            if sep and e:
                var stacked: bool = false
                if e.get_child_count() > 0:
                    stacked = !e.get_node("vbox/sender").visible
                init_sep_timer(e, sep, stacked)

func init_sep_timer(msg: Control, sep: HSeparator, stack: bool) -> void:
    var timer = Timer.new()
    $messages.add_child(timer)
    timer.one_shot = true
    timer.wait_time = 0.1
    timer.connect("timeout", self, "sep_timer", [timer, msg, sep, stack])
    timer.start()

func sep_timer(timer: Timer, msg: Control, sep: HSeparator, stack: bool) -> void:
    timer.queue_free()
    
    var con: Label = msg.get_node("vbox/content")
    
    if con:
        var separation: int
        if stack == true:
            separation = 4
        else:
            separation = con.rect_size.y
        sep.add_constant_override("separation", separation)
    
    var tiemr = Timer.new()
    $messages.add_child(tiemr)
    tiemr.one_shot = true
    tiemr.wait_time = 0.1
    tiemr.connect("timeout", self, "msg_timer", [tiemr, msg, sep, stack])
    tiemr.start()

func msg_timer(timer: Timer, msg: Control, sep: HSeparator, stack: bool) -> void:
    timer.queue_free()
    
    var con: Label = msg.get_node("vbox/content")
    var date: Label = msg.get_node("vbox/sender/hbox/timestamp/date")
    var time: Label = msg.get_node("vbox/sender/hbox/timestamp/time")
    var sendername: Label = msg.get_node("vbox/sender/hbox/sendername")
    var senderpic: TextureRect = msg.get_node("vbox/sender/senderpic")
    
    if con:
        var margin = msg.margin_bottom + con.rect_size.y
        if stack == true:
            msg.rect_min_size.y = con.rect_size.y + (con.get_line_height() / 2)
            con.margin_top = 0
            margin = (msg.margin_bottom - msg.rect_size.y) + con.rect_size.y
        msg.margin_bottom = margin
        $messages/scroll.scroll_vertical = $messages/scroll.scroll_vertical + msg.rect_size.y
       




func UPDATE_MESSAGE_SENDER_PFP(texture: ImageTexture, kwargs: Array) -> void:
    # kwargs[0] is always UID
    var msgt: String = kwargs[1].replace(".","")
    var msg = $messages/scroll/list.get_node(msgt)
    msg.get_node("vbox/sender/senderpic").texture = texture
    
    var suid: String = kwargs[0]
    if cache.has_section_key("users", suid) == true:
        var dat: Dictionary = cache.get_value("users", suid)
        dat["picture"] = "pfp/%s.%s" % [suid, api.get_image_extension_from_url(kwargs[2])]
        cache.set_value("users", suid, dat)
    
func UPDATE_MESSAGE_SENDER_NAME(data: Dictionary) -> void:
    var msgt: String = MSG_N_CALL[0]
    var sname: String = data["username"]
    var msgn = $messages/scroll/list.get_node(msgt)
    msgn.get_node("vbox/sender/hbox/sendername").text = sname
    
    var suid = data["uid"]
    if cache.has_section_key("users", suid) == false:
        cache.set_value("users", suid, {
            "username": sname,
            "picture": ""
        })
    else:
        var dat: Dictionary = cache.get_value("users", suid)
        dat["username"] = sname
        cache.set_value("users", suid, dat)
    cache.save(CACHE_PATH)
    
    MSG_N_CALL.remove(0)
    
    api.GET_USER_PROFILE_PICTURE(data["photo_url"], suid, [msgt, data["photo_url"]], self, "UPDATE_MESSAGE_SENDER_PFP")
