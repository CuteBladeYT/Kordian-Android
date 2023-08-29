extends Node

func sha256(text: String) -> String:
    return text.sha256_text()
    
func create_http_request(rname: String) -> HTTPRequest:
    var rq = HTTPRequest.new()
    rq.name = sha256(rname)
    return rq
