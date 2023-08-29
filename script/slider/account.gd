extends Control

func _ready() -> void:
    $login.show()
    $scroll.hide()
    $logging_in_label.hide()
    $logging_in_label/progress.value = 0

func user_logged_in() -> void:
    $login.hide()
    $scroll.show()
    $logging_in_label.hide()
    
    Notification.add_to_history("Logged in as " + User.username)

func update_data() -> void:
    var timer = self.get_parent().get_parent().get_node("token_expired")
    timer.stop()
    timer.start(0)
    
    var dt = Tweaks.get_time_dict(OS.get_unix_time() + int(timer.time_left))
    dt["hour"] = str(int(dt["hour"]) + dt["offset"])
    var label = $scroll/content/margin/buttons/session_time
    var expt = "%s:%s.%s" % [dt["hour"], dt["minute"], dt["second"]]
    label.text = "%s %s" % [tr("account_profile_session_time"), expt]
    label.hint_tooltip = expt
    
    
    $login.hide()
    $scroll.hide()
    $logging_in_label.show()
    $logging_in_label/progress.value = 0
    api.callmap[api.API_ACCOUNTS_GET_UID] = [self, "get_data_pt1"]
    api.GET_ACCOUNT_UID(User.token)
    return

func get_data_pt1(uid: String) -> void:
    User.uid = uid
    api.callmap[api.API_ACCOUNTS_GET_INFO] = [self, "get_data_pt2"]
    api.GET_ACCOUNT_DATA(uid)
    $logging_in_label/progress.value = 2
    return

func get_data_pt2(data: Dictionary) -> void:
    User.username = data["username"].percent_decode()
    User.email = data["email"].percent_decode()
    User.email_verified = data["email_verified"]
    User.picture_url = data["photo_url"].percent_decode()
    User.badges["verified"] = data["badges"]["is_verified"]
    User.badges["developer"] = data["badges"]["is_developer"]
    User.privacy["email_visible"] = data["privacy"]["email_visible"]
    
    $scroll/content/margin/profile/name.text = User.username
    $scroll/content/margin/profile/uid.text = User.uid
    $scroll/content/margin/badges/developer.visible = User.badges["developer"]
    $scroll/content/margin/badges/verified.visible = User.badges["verified"]
    $scroll/content/margin/buttons/verify_email.visible = !User.email_verified
    var skip_picture: bool = false
    if User.picture_url is String:
        if User.picture_url.length() > 4:
            api.GET_USER_PROFILE_PICTURE(User.picture_url, User.uid, [], self, "update_profile_pic")
        else:
            skip_picture = true
    else:
        skip_picture = true
    if skip_picture == true:
        user_logged_in()
    $logging_in_label/progress.value = 3
    return

func update_profile_pic(texture: ImageTexture, kwargs: Array) -> void:
    if texture is ImageTexture:
        User.picture_texture = texture
        $scroll/content/margin/profile/img.texture = texture
        get_parent().get_parent().get_node("navbar/layout/account/img").texture = texture
    $logging_in_label/progress.value = 4    
    user_logged_in()


func SHOW_EDIT_DATA_FORM() -> void:
    $scroll/content/margin/buttons.hide()
    $scroll/content/margin/edit_data.show()
    $scroll/content/margin/edit_data/username.text = ""
    $scroll/content/margin/edit_data/profile_url.text = ""

func CANCEL_DATA_EDIT() -> void:
    $scroll/content/margin/buttons.show()
    $scroll/content/margin/edit_data.hide()


func EDIT_DATA_SAVE() -> void:
    var username = $scroll/content/margin/edit_data/username.text
    var picurl = $scroll/content/margin/edit_data/profile_url.text
    var pwd = $scroll/content/margin/edit_data/password.text
    var pwdr = $scroll/content/margin/edit_data/password_repeat.text
    
    if username.length() > 0:
        api.callmap[api.API_ACCOUNTS_UPDATE_USERNAME] = [self, "DATA_EDIT_RESPONSE"]
        api.UPDATE_USER_NAME(User.token, username)
    if picurl.length() > 0:
        api.callmap[api.API_ACCOUNTS_UPDATE_PICTURE_URL] = [self, "DATA_EDIT_RESPONSE"]
        api.UPDATE_USER_PICTURE_URL(User.token, picurl)
    if pwdr.length() > 0:
        if pwdr.length() > 0:
            api.callmap[api.API_ACCOUNTS_UPDATE_PASSWORD] = [self, "DATA_EDIT_RESPONSE"]
            api.UPDATE_USER_PASSWORD(User.token, pwd)
    else:
        $scroll/content/margin/edit_data/password.text = ""
        $scroll/content/margin/edit_data/password_repeat.text = ""
        $scroll/content/margin/edit_data/password.placeholder_text = tr("account_login_note_short_password")

func DATA_EDIT_RESPONSE(res) -> void:
    if $scroll/content/margin/edit_data/username.text.length() > 0 or $scroll/content/margin/edit_data/profile_url.text.length() > 0:
        update_data()
    $scroll/content/margin/edit_data/username.text = ""
    $scroll/content/margin/edit_data/profile_url.text = ""


func _on_change_password_text_changed(new_text: String) -> void:
    if new_text.length() > 0:
        $scroll/content/margin/edit_data/password_repeat.show()
    else:
        $scroll/content/margin/edit_data/password_repeat.hide()
        $scroll/content/margin/edit_data/password_repeat.text = ""


func VERIFY_EMAIL() -> void:
    if User.email_verified == false:
        api.callmap[api.API_ACCOUNTS_VERIFY_EMAIL] = [self, "email_verify_response"]
    else:
        $scroll/content/margin/buttons/verify_email.hide()
        
func email_verify_response(res: String) -> void:
    if res == "0":
        update_data()


func RESTART_SESSION() -> void:
    update_data()
