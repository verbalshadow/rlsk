extends Reference

class_name Dungeon

enum Tiles { BRICK, DIRT, WALL }
var level = Array2D.new()
export var SCREEN_WIDTH := 80
export var SCREEN_HEIGHT := 60
export var TEXTBOX_HEIGHT := 0

var MAP_WIDTH = SCREEN_WIDTH
var MAP_HEIGHT = SCREEN_HEIGHT - TEXTBOX_HEIGHT

export var USE_PREFABS := false


func center(room : Rect2):
	var center = room.size/2 + room.position
	return Vector2(int(center.x), int(center.y))