extends Node

var token := ""
var uid := ""
var username := ""
var email := ""
var email_verified := false
var picture_url := ""
var picture_texture: ImageTexture
var badges = {
    "verified": false,
    "developer": false
}
var privacy = {
    "email_visible": true
}
