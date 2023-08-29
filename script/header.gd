extends Control

onready var slider = get_parent().get_node("slider_panel")

func _ready() -> void:
    pass # Replace with function body.


func _on_menu_pressed() -> void:
    slider.slider_visibility(!slider.visible)
