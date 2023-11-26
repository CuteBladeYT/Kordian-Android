extends Control

func _ready() -> void:
    yield(get_tree().create_timer(.1),"timeout")
    $scroll/container/roomid.value = Tweaks.settings["app"]["last_room_id"]

func _on_random_room_pressed() -> void:
    var rid = $scroll/container/roomid
    
    var id = Tweaks.RNG.randf_range(rid.min_value, rid.max_value)
    
    print(id)
    rid.value = id


func _on_copy_invite_pressed() -> void:
    var code = $scroll/container/roomid.value
    OS.set_clipboard(str(code))


func _on_paste_invite_pressed() -> void:
    var code = OS.get_clipboard()
    
    if int(code):
        $scroll/container/roomid.value = int(code)
