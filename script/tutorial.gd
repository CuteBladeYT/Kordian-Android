extends Control

var next_anim

func _ready() -> void:
    self.hide()
    return
    $actions/continue.show()
    yield(get_tree().create_timer(.1),"timeout")
    if Tweaks.FIRST_RUN == true:
        $anim.play("0")

func set_label_text(text: String) -> void:
    $text.text = tr(text)


func _on_finish_pressed() -> void:
    $anim.play("finish")


func _on_anim_animation_finished(anim_name: String) -> void:
    var anim = int(anim_name)
    next_anim = str(anim+1) if $anim.has_animation(str(anim+1)) else "finish"
    $actions/continue.disabled = false
    if next_anim == "finish":
        $actions/continue.hide()
    else:
        $actions/continue.show()


func _on_anim_animation_started(anim_name: String) -> void:
    $actions/continue.disabled = true


func _on_continue_pressed() -> void:
    $anim.play(next_anim)
