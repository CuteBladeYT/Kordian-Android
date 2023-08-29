extends Control

func _ready() -> void:
    api.reconTimeout = self.get_node("api_reconnect")
    api.reconTimeout.connect("timeout", api, "api_reconnect")
    api.REQS = self.get_node("requests")
    OS.request_permissions()
    _update_resolution()
    update_appearance()
    
    if OS.is_debug_build():
        $debug.text = "PERSMISSIONS: %s\nUSER DATA PATH: %s" % [
            OS.get_granted_permissions(), Tweaks.PATHS
        ]
    else:
        $debug.queue_free()
        
    Notification.list = get_node("notif/list")
    Notification.history = get_node("slider_panel/notifs/scroll/list")
        
    # PING SERVER
    #api.PING_SERVER(self, "SERVER_PING_RESULT")
    
    #TranslationServer.set_locale("pl")

func SERVER_PING_RESULT(result, ___d0, ___d1, ___d2) -> void:
    if result == 0:
        print(tr("api_connection_estabilished"))

func update_appearance() -> void:
    var s = Tweaks.settings
    var header_height = s["appearance"]["header_height"]
    var navbar_height = s["appearance"]["navbar_height"]
    $header.margin_bottom = header_height
    $slider_panel.margin_top = header_height
    $slider_panel.margin_bottom = -navbar_height
    $content/messages.margin_top = header_height
    $content/messages.margin_bottom = -navbar_height
    $navbar.margin_top = -navbar_height
    $content/input.margin_top = -navbar_height
    
    #$content/input/send.visible = s["appearance"]["show_message_send_button"] if Tweaks.IS_ANDROID else false
    #if $content/input/send.visible == true:
    #    $content/input/msg.margin_right = -navbar_height + 3
    #else:
    #    $content/input/msg.margin_right = 0
    
    $slider_panel/account/scroll/content/margin/buttons/session_time.text = "%s %s" % [tr("account_profile_session_time"), $slider_panel/account/scroll/content/margin/buttons/session_time.hint_tooltip]

func _update_resolution() -> void:
    var ui_scale = Tweaks.settings["appearance"]["ui_scale"]
    var screensize = OS.get_screen_size()
    get_tree().set_screen_stretch(
        SceneTree.STRETCH_MODE_2D,
        SceneTree.STRETCH_ASPECT_EXPAND,
        Vector2(screensize), ui_scale
    )


func TOKEN_EXPIRED() -> void:
    $token_expired.stop()
    Notification.add_notif(tr("session_expired"))
    $content.CONNECTED = false
    $content.ROOMID = -1
    $content.APPEND_FETCH_MESSAGES({}, true)
    
    $slider_panel/account/login.show()
    $slider_panel/account/scroll.hide()
    $slider_panel.slider_set_screen($slider_panel/account.name)
    $slider_panel.slider_visibility(true)
