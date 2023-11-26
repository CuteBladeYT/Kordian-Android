extends Node

var IS_ANDROID = OS.get_name().to_lower() == "Android".to_lower()

var PATHS = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).replace("Documents", "") + "Android/data/com.ampstudio.kordian/files/" if IS_ANDROID == true else "user://"

var SETTINGS_FILE_PATH = PATHS+ "settings.ini"

var CHAT_DEF_HEIGHT: int

var FIRST_RUN = true

var RNG := RandomNumberGenerator.new()

func _ready() -> void:
    var dir = Directory.new()
    if not dir.dir_exists(PATHS+ "pfp"):
        dir.make_dir(PATHS+ "pfp")
    if not dir.dir_exists(PATHS+ "0"):
        dir.make_dir(PATHS+ "0")

var cfg = ConfigFile.new()

var settings = {
    "appearance": {
        "ui_scale": 1.0,
        "header_height": 128,
        "navbar_height": 128,
        "keyboard_shrink": 0,
        "show_message_send_button": true
    },
    "app": {
        "language": "en",
        "auto_login": true,
        "last_room_id": 0
    }
}

func save_settings() -> void:
    cfg.clear()
    for section in settings.keys():
        for key in settings[section].keys():
            var value = settings[section][key]
            cfg.set_value(section, key, value)
    cfg.save(SETTINGS_FILE_PATH)

func load_settings():
    var err = cfg.load(SETTINGS_FILE_PATH)
    if err:
        if err == 7:
            FIRST_RUN = true
            printerr("Settings file doesn't exist")
        return err
    for section in cfg.get_sections():
        for key in cfg.get_section_keys(section):
            var value = cfg.get_value(section, key)
            settings[section][key] = value


func get_time_dict(timestamp: int) -> Dictionary:
    var datetime: Dictionary = OS.get_datetime_from_unix_time(timestamp)
    var timezone_bias: int = Time.get_time_zone_from_system()["bias"]
    timezone_bias = timezone_bias
    var offset: int = timezone_bias / 60 # offset in minutes divided by an hour (so the output is hour)
    
    for n in ["year", "month", "day", "hour", "minute", "second"]:
        if str(datetime[n]).length() == 1:
            datetime[n] = "0" + str(datetime[n])
    datetime["offset"] = offset
    return datetime
func get_timezone_offset() -> int:
    var timezone_bias: int = Time.get_time_zone_from_system()["bias"]
    timezone_bias = timezone_bias
    var offset: int = timezone_bias / 60 # offset in minutes divided by an hour (so the output is hour)
    return offset
