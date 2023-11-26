extends Node

var list: VBoxContainer
var history: VBoxContainer

func add_notif(text: String, color = Colors.theme["colors"]["text"]) -> void:
    var n = Label.new()
    n.text = text
    n.mouse_filter = Control.MOUSE_FILTER_STOP
    n.focus_mode = Control.FOCUS_CLICK
    n.autowrap = true
    if color: n.add_color_override("font_color", color)
    n.connect("focus_entered", self, "remove_notif", [n])
    list.add_child(n)
    add_to_history(text, color)
    var timer = Timer.new()
    timer.one_shot = true
    timer.wait_time = 5
    timer.connect("timeout", self, "timer_timeout", [timer, n])
    history.add_child(timer)
    timer.start()
    return

func add_to_history(text: String, color = Colors.theme["colors"]["text"]) -> void:
    var n = Label.new()
    n.text = text
    if color: n.add_color_override("font_color", color)
    
    var t = Label.new()
    t.add_stylebox_override("normal", StyleBoxEmpty.new())
    var time = Times.get_time_string()
    t.text = "\n" + time
    n.autowrap = true
    
    t.mouse_filter = Control.MOUSE_FILTER_IGNORE
    n.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    history.add_child(t)
    history.add_child(n)
    
    yield(get_tree().create_timer(.1),"timeout")
    var s: ScrollContainer = history.get_parent()
    s.scroll_vertical = history.rect_size.y
    return

func remove_notif(notif: Label) -> void:
    if list.has_node(notif.name):
        list.remove_child(notif)
        notif.queue_free()
    return

func timer_timeout(timer: Timer, n: Label) -> void:
    timer.queue_free()
    
    if n:
        n.queue_free()
