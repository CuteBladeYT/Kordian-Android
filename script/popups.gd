extends Control

func _ready() -> void:
    bgimg_grabber_following = true
    $background_image/grabber.margin_top = 512
    $background_image/grabber.margin_bottom = 512+32
    bgimg_grabber_following = false

func _on_settings_theme_file_popup_pressed() -> void:
    $open_theme_file.popup()
    
func select_background_image() -> void:
    var bi = $background_image
    var popup = $background_image/popup
    var path = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
    popup.current_path = path
    popup.current_dir = path
    popup.popup()


var BG_IMG_PATH: String
func _on_background_image_file_selected(path: String) -> void:
    BG_IMG_PATH = path
    update_bg_img_preview(path)
    $background_image/confirm.popup()

func _on_popup_about_to_show() -> void:
    $bg.show()
    $background_image.show()
    $background_image/preview.show()

func _on_popup_popup_hide() -> void:
    $bg.hide()
    $background_image.hide()
    $background_image/confirm.hide()
    $background_image/popup.hide()

var UPDATE_BG_IMG_PREVIEW_LAST_PATH: String
func update_bg_img_preview(path) -> void:
    var img = Image.new()
    img.load(path)
    print(path)
    
    var t = ImageTexture.new()
    t.create_from_image(img)
    
    $background_image/preview.texture = t

var bgimg_grabber_following: bool = false
func _on_bgimg_grabber_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == 1:
            bgimg_grabber_following = !bgimg_grabber_following
func _process(delta: float) -> void:
    if bgimg_grabber_following:
        var grabber = $background_image/grabber
        var mp = get_local_mouse_position().y
        grabber.margin_top = mp
        grabber.margin_bottom = mp+32
        $background_image/popup_show.margin_bottom = grabber.margin_top
        $background_image/popup.margin_bottom = grabber.margin_top
        $background_image/confirm.margin_bottom = grabber.margin_bottom
        $background_image/preview.margin_top = grabber.margin_bottom


func _on_popup_show_pressed() -> void:
    $background_image/popup.popup()


func _on_confirm_confirmed() -> void:
    Colors.theme["background"]["image"] = BG_IMG_PATH
    Colors.save_theme()
    get_parent().get_node("bg").get_theme_image()
    _on_popup_popup_hide()


func _on_confirm_popup_hide() -> void:
    $background_image/popup.popup()
