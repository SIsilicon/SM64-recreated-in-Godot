extends Node

var coin_counter := 0

var debug_blj := false

var mario : Mario
var camera : Spatial

var star_fanfare := AudioStreamPlayer.new()

func _ready():
	star_fanfare.volume_db = linear2db(0.1)
	star_fanfare.stream = preload("res://Assets/Music/star_fanfare.ogg")
	add_child(star_fanfare)

func play_star_fanfare():
	star_fanfare.play()