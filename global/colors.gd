extends Node

var cfg = ConfigFile.new()
onready var THEME_FILE = Tweaks.PATHS+ "theme.ini"

var theme = {
    "colors": {
        "accent": Color("74c7ec"),
        "accent_dark": Color("5e81b9"),
        "accent_light": Color("89dceb"),

        "border": Color("cdd6f4"),
        "hover": Color("fab387"),
        "hover2": Color("cba6f7"),
        "activated": Color("a6e3a1"),
        "disabled": Color("f38b8b"),
        "url": Color("74c7ec"),

        "text": Color("cdd6f4"),
        "text_grey": Color("6c7086"),
        "text_dark": Color("313244"),

        "background": Color("181825"),
        "background_panel": Color("11111b"),
        "background_popup": Color("1e1e2e")
    },
    "background": {
        "image": "",
        "alpha": 1.0
    }
}

func _ready() -> void:
    load_theme()
    
func load_theme() -> int:
    var err = cfg.load(THEME_FILE)
    if err != OK:
        return err 
    
    for section in cfg.get_sections():
        for key in cfg.get_section_keys(section):
            var value = cfg.get_value(section, key)
            if section == "colors":
                value = Color(value)
            theme[section][key] = value
    
    return err

func save_theme() -> int:
    cfg.clear()
    
    for section in theme.keys():
        for key in theme[section].keys():
            var value = theme[section][key]
            
            cfg.set_value(section, key, value)
    
    var err = cfg.save(THEME_FILE)
    return err
