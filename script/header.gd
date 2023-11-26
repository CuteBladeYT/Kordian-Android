extends Control

onready var slider = get_parent().get_node("slider_panel")

func _ready() -> void:
    pass


func _on_menu_pressed() -> void:
    slider.slider_visibility(!slider.visible)
