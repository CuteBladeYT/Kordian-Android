extends Control

onready var reqs = get_parent().get_node("requests")
var GET_THEME_RQ: HTTPRequest

var PATHS = Tweaks.PATHS

func _ready() -> void:
    $color.modulate = Colors.theme["colors"]["background"]
    
    if Colors.theme["background"]["image"] != "":
        get_theme_image()
        #var img = ""
        #var extensions = ["png","jpg","jpeg","webp"]
        #var tries := 0
        #for ext in extensions:
        #    img = __GET_THEME_BACKGROUND("","","","",ext)
        #    if img is int or img == null:
        #        if tries > extensions.size()-1:
        #            get_theme_image()
        #    else:
        #        $image.texture = img
        #        break
        #    tries += 1
    
    if Colors.theme["background"]["alpha"] < 1:
        $color.modulate = Color.black

    $color.modulate.a = Colors.theme["background"]["alpha"]

func get_theme_image() -> void:
    var url = Colors.theme["background"]["image"]
    var img = Image.new()
    img.load(url)
    var txt = ImageTexture.new()
    txt.create_from_image(img)
    $image.texture = txt
    return
    if url != "":
        var image_ext = url.split(".")[url.split(".").size()-1]
        GET_THEME_RQ = Requests.create_http_request(url)
        reqs.add_child(GET_THEME_RQ)
        GET_THEME_RQ.download_file = PATHS+ "background." + image_ext
        GET_THEME_RQ.connect("request_completed", self, "__GET_THEME_BACKGROUND", [image_ext])
        GET_THEME_RQ.request(url)
    
func __GET_THEME_BACKGROUND(result = "", response_code = "", headers = "", body = "", image_ext = ""):
    if GET_THEME_RQ:
        if reqs.has_node(GET_THEME_RQ.name):
            reqs.remove_child(GET_THEME_RQ)
    var image = Image.new()
    var err = image.load(PATHS+ "background." + image_ext)
    if err != OK:
        return int(err)
    var texture = ImageTexture.new()
    texture.create_from_image(image, 0)
    $image.texture = texture
    return texture
