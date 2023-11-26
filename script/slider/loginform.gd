extends Control

var cfg = ConfigFile.new()
var creddatapath = Tweaks.PATHS+ "0/lastlogin.ini"
#var autologintimer := Timer.new()

func _ready() -> void:
    api.loginform = self
    _on_register_toggled(false)
    var cred = load_login_data()
    if cred is Dictionary:
        var email = cred["email"]
        var pwd = cred["password"]
        $form/email.text = email
        $form/password.text = pwd

func _on_login_pressed() -> void:
    #if autologintimer:
    #    autologintimer.queue_free()
        
    var inemail = $form/email
    var inpwd = $form/password
    var inpwdr = $form/password_repeat
    
    var email = inemail.text
    var pwd = inpwd.text
    var pwdr = inpwdr.text
    
    var isRegistering = $form/register.pressed
    
    $form/note.text = ""
    
    if email.find(" ") > 0 or pwd.find(" ") > 0:
        $form/note.text = tr("account_login_note_no_spaces")
        return
    
    if email.length() < 5:
        $form/note.text = tr("account_login_note_incorrect_email")
        return
    elif not email.match("@") and email.find(".") < 1:
        $form/note.text = tr("account_login_note_incorrect_email")
        return

    if pwd.length() < 5:
        $form/note.text = tr("account_login_note_short_password")
        return
    
    if isRegistering:
        if pwdr == pwd:
            api.callmap[api.API_ACCOUNTS_REGISTER] = [self, "REGISTER_RQ_COMPLETE"]
            api.REGISTER_ACCOUNT(email, pwd)
        else:
            return
    else:
        api.callmap[api.API_ACCOUNTS_LOGIN] = [self, "LOGIN_RQ_COMPLETE"]
        api.LOGIN_ACCOUNT(email, pwd)
        print("LOGGIN IN...")
    $form/login.disabled = true
    
func LOGIN_RQ_COMPLETE(res) -> void:
    if not res is int and res.begins_with("ERR::"):
        printerr("ERROR WHILE LOGGING IN TO ACCOUNT\n" + res)
        return
    
    User.token = res
    
    get_parent().update_data()
    
    save_login_data($form/email.text, $form/password.text)
    
    $form/email.text = ""
    $form/password.text = ""
    $form/login.disabled = false
    
    get_parent().get_node("logging_in_label/progress").value = 1
    return

func REGISTER_RQ_COMPLETE(res: String) -> void:
    var msg: String = ""
    if res.begins_with("ERR::"):
        var err = res.split("ERR::")[1]
        match int(err[0]):
            1:
                msg = tr("account_login_note_user_exist")
            2:
                msg = tr("account_login_note_short_password")
            3:
                msg = tr("account_login_note_incorrect_email")
                
        $form/note.text = msg
        $form/password.text = ""
        $form/password_repeat.text = ""
        
    else:
        msg = tr("account_register_success")
        Notification.add_notif(msg)

func save_login_data(email: String, password: String) -> void:
    cfg.clear()
    cfg.set_value("", "email", email)
    cfg.set_value("", "password", password)
    cfg.save(creddatapath)

func remove_login_data() -> void:
    var dir = Directory.new()
    if dir.file_exists(creddatapath):
        dir.remove(creddatapath)

func load_login_data():
    cfg.clear()
    var err = cfg.load(creddatapath)
    if err != OK:
        return err
    
    return {
        "email": cfg.get_value("", "email"),
        "password": cfg.get_value("", "password")
    }


func _on_register_toggled(isRegister: bool) -> void:
    var msg = [tr("account_login_btn_login"), tr("account_login_btn_register")]
    var prin = $form/password_repeat
    if isRegister == true:
        prin.modulate = Color.white
        prin.mouse_filter = Control.MOUSE_FILTER_STOP
    else:
        prin.modulate = Color.transparent
        prin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    #$form/register.text = msg[0] if isRegister else msg[1]
    $form/login.text = msg[1] if isRegister else msg[0]


func reset_password() -> void:
    var email = $form/email.text
    api.RESET_PASSWORD(email)
    
    $form/login.disabled = true
    $form/reset_password.disabled = true


func _on_show_password_toggled(button_pressed: bool) -> void:
    $form/password.secret = !button_pressed
    $form/password_repeat.secret = !button_pressed
