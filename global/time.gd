extends Node

func get_time_string(hours := true, minutes := true, seconds := true) -> String:
    var tt = OS.get_time()
    var t := ""
    var hour = str(tt["hour"])
    var minute = str(tt["minute"])
    var second = str(tt["second"])
    if hours:
        if hour.length() == 1:
            hour = "0" + hour
        t += hour
        if minutes: t += ":"
    if minutes:
        if minute.length() == 1:
            minute = "0" + minute
        t += minute
        if seconds: t += ":"
    if seconds:
        if second.length() == 1:
            second = "0" + second
        t += second
    return t
