extends Control

func _ready() -> void:   
    var sload_err = Tweaks.load_settings()
    
    #if typeof(sload_err) is int:
    Tweaks.save_settings()
    
    for lang in TranslationServer.get_loaded_locales():
        $scroll/container/app_language.add_item(lang)
    
    var s = Tweaks.settings
    $scroll/container/ui_scale_value.value = s["appearance"]["ui_scale"]
    $scroll/container/header_height_value.value = s["appearance"]["header_height"]
    $scroll/container/navbar_height_value.value = s["appearance"]["navbar_height"]
    
    $scroll/container/keyboard_shrink_value.editable = Tweaks.IS_ANDROID
    $scroll/container/keyboard_shrink_value.value = s["appearance"]["keyboard_shrink"]
    $scroll/container/keyboard_shrink_scale_value.value = s["appearance"]["keyboard_shrink_scale"]
    
    $scroll/container/show_message_send_button.disabled = !Tweaks.IS_ANDROID
    $scroll/container/show_message_send_button.pressed = s["appearance"]["show_message_send_button"]
    
    for i in $scroll/container/app_language.get_item_count():
        var item = $scroll/container/app_language.get_item_text(i)
        if item == s["app"]["language"]:
            $scroll/container/app_language.select(i)
            TranslationServer.set_locale(item)
            break
    
    $scroll/container/app_auto_login.pressed = s["app"]["auto_login"]
    api.autologin = s["app"]["auto_login"]

    _on_settings_save_pressed()

func _on_settings_save_pressed() -> void:
    var s = Tweaks.settings
    s["appearance"]["ui_scale"] = $scroll/container/ui_scale_value.value
    s["appearance"]["header_height"] = $scroll/container/header_height_value.value
    s["appearance"]["navbar_height"] = $scroll/container/navbar_height_value.value
    s["appearance"]["keyboard_shrink"] = $scroll/container/keyboard_shrink_value.value
    s["appearance"]["keyboard_shrink_scale"] = $scroll/container/keyboard_shrink_scale_value.value
    s["appearance"]["show_message_send_button"] = $scroll/container/show_message_send_button.pressed
    s["app"]["language"] = $scroll/container/app_language.get_item_text($scroll/container/app_language.selected)
    s["app"]["auto_login"] = $scroll/container/app_auto_login.pressed
    Tweaks.save_settings()
    
    TranslationServer.set_locale(s["app"]["language"])
    get_parent().get_parent()._update_resolution()
    get_parent().get_parent().update_appearance()
    
    Tweaks.CHAT_DEF_HEIGHT = self.get_parent().get_parent().get_node("content").rect_size.y

    for c in $scroll/container.get_children():
        if c is Label:
            if c.hint_tooltip.length() > 0:
                if c.text.find(" - ") > 0:
                    var val = c.text.split(" - ")[1]
                    c.text = "%s - %s" % [tr(c.hint_tooltip), val]

func update_slider_text_value(value: float, item: String, suffix := "") -> void:
    var container = self.get_node("scroll/container")
    if container.has_node(item):
        var n: Label = container.get_node(item)
        
        n.text = tr(n.hint_tooltip) + " - " + str(value) + suffix
        
        if api.APP:
            $scroll/container/keyboard_shrink_value.max_value = api.APP.rect_size.y / $scroll/container/keyboard_shrink_scale_value.value

func _theme_file_selected(path: String) -> void:
    pass # Replace with function body.
