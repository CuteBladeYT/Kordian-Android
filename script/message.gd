extends Control


export(String, "Left", "Right", "None") var ARROW: String = "Left"
export(String, "Left", "Right") var ALIGNMENT: String = "Left"
export(Texture) var PROFILE_PICTURE: Texture
export(String) var HEADER: String = ""
export(String, MULTILINE) var MESSAGE: String
export var DATETIME: String = ""

export var done_once_wrapping = false

class string_length_sorter:
    static func sort_ascending(a, b):
        if a.length() < b.length():
            return true
        return false
    static func sort_descending(a, b):
        if a.length() > b.length():
            return true
        return false
        
func _process(_delta):
    update_ui_msg()
    
func update_ui_msg():
    var color: Color
    # Setting the arrow direction for the bubble
    if ARROW == "Left":
        color = Colors.theme["colors"]["accent_dark"]
        $margin/arrow_left.show()
        $margin/arrow_right.hide()
        $margin/arrow_left.get_stylebox("panel", "").modulate_color = color
        
        var new_stylebox_normal = $margin/bubble.get_stylebox("panel").duplicate()
        new_stylebox_normal.bg_color = color
        $margin/bubble.add_stylebox_override("panel", new_stylebox_normal)
    elif ARROW == "Right":
        color = Colors.theme["colors"]["accent"]
        $margin/arrow_left.hide()
        $margin/arrow_right.show()
        $margin/arrow_right.get_stylebox("panel", "").modulate_color = color
        
        var new_stylebox_normal = $margin/bubble.get_stylebox("panel").duplicate()
        new_stylebox_normal.bg_color = color
        $margin/bubble.add_stylebox_override("panel", new_stylebox_normal)
    elif ARROW == "None":
        $margin/arrow_left.hide()
        $margin/arrow_right.hide()
        
        color = Colors.theme["colors"]["accent_dark"]
        
        var new_stylebox_normal = $margin/bubble.get_stylebox("panel").duplicate()
        new_stylebox_normal.bg_color = color
        $margin/bubble.add_stylebox_override("panel", new_stylebox_normal)

    # Make the Chat bubble node grow according to the 
    # Message label node
    rect_size.y = $margin/bubble/content.rect_size.y + $margin/bubble/content.rect_position.y + $margin.get_constant("margin_top") + ($margin/bubble/author.rect_size.y * 2) - 22
#	rect_size.x = min($Bubble_margin/Bubble/Message.rect_position.x + ($Bubble_margin/Bubble/Message.rect_size.x) +  $Bubble_margin.get_constant("margin_left") + $Bubble_margin.get_constant("margin_right") + 25, 
#	550) # this number is what the size of Chatbubble will stop at when expanding cuz of Message

    # Inputs
    $margin/bubble/pfp.texture = PROFILE_PICTURE
    $margin/bubble/author.text = str(HEADER)
    $margin/bubble/content.text = str(MESSAGE)
    $margin/bubble/date.text = str(DATETIME)

#	Get the length/size of the Longest line in Message
    var message_lines = $margin/bubble/content.text.split("\n", true) as Array
    message_lines.sort_custom(string_length_sorter, "sort_descending")

#	Use the longest Line length to resize the chat bubble
    var max_characters = 90 
    var character_width = 7
    var max_width = api.APP.rect_size.x
    #rect_size.x = min($margin/bubble/content.rect_position.x + (character_width * max_characters),
    #$margin/bubble/content.rect_position.x + (character_width * message_lines[0].length()))
    rect_size.x = min($margin/bubble/content.rect_position.x + max_width,
    $margin/bubble/content.rect_position.x + (character_width * message_lines[0].length()))
    
    if rect_size.x > max_width:
        rect_size.x = max_width
    #$margin/bubble/author.rect_size.x

    # Setting the Bubble Alignment
    if ALIGNMENT == "Left":
        pass
    elif ALIGNMENT == "Right":
        self.anchor_left = 1
        self.anchor_right = 1
        self.margin_left = -self.rect_size.x
        
# run only in the game
    if not Engine.editor_hint:
        pass
