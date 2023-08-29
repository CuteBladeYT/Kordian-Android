extends Control

onready var navbar: Control = get_parent().get_node("navbar")
onready var content: Control = get_parent().get_node("content")

func _ready() -> void:
    $SwipeModule.Activate()
    slider_visibility(true)
    slider_set_screen("account")

func slider_set_screen(screen: String) -> void:
    var screens = [$roomcfg, $settings, $notifs, $account]
    if self.has_node(screen):
        var scn = self.get_node(screen)
        if self.visible == true:
            if scn.visible == true:
                slider_visibility(false)
                return
        else:
            slider_visibility(true)
        
        for iscn in screens:
            iscn.hide()
        
        scn.show()

func slider_visibility(vis: bool) -> void:
    if vis == true:
        if self.visible == false:
            $anim.play("show")
            navbar.get_node("anim").play("show")
            content.get_node("anim").play("hide")
    else:
        if self.visible == true:
            $anim.play("hide")
            navbar.get_node("anim").play("hide")
            content.get_node("anim").play("show")
            content.update_ui()

func _input(event) -> void:
    if event is InputEventSwipe:
        if event.left():
            slider_visibility(false)
        elif event.right():
            slider_visibility(true)
