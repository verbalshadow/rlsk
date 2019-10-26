extends Dungeon

class_name BSPTree

var room = null
export var MAX_LEAF_SIZE = 30
export var ROOM_MAX_SIZE = 28
export var ROOM_MIN_SIZE = 6

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	# Creates an empty 2D array or clears existing array
	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.WALL)

	var _leafs = []

	var rootLeaf = Leaf.new(0,0,mapWidth,mapHeight)
	_leafs.append(rootLeaf)

	var splitSuccessfully = true
	# loop through all leaves until they can no longer split successfully
	while (splitSuccessfully):
		splitSuccessfully = false
		for l in _leafs:
			if (l.child_1 == null) and (l.child_2 == null):
				if ((l.width > MAX_LEAF_SIZE) or 
				(l.height > MAX_LEAF_SIZE) or
				(randf() > 0.8)):
					if (l.splitLeaf()): #try to split the leaf
						_leafs.append(l.child_1)
						_leafs.append(l.child_2)
						splitSuccessfully = true

	rootLeaf.createRooms(self)

	return level

func carveRoom(room):
	# set all tiles within a rectangle to 0
	for x in range(room.position.x + 1, room.end.x):
		for y in range(room.position.y+1, room.end.y):
			level.set_cell(x, y, Tiles.DIRT)

func carveHall(room1, room2):
	# connect two rooms by hallways
	var room1c = center(room1)
	var room2c = center(room2)
	# 50% chance that a tunnel will start horizontally
	if randi() % 2 == 1:
		carveHorTunnel(room1c.x, room2c.x, room1c.y)
		carveVirTunnel(room1c.y, room2c.y, room2c.x)

	else: # else it starts virtically
		carveVirTunnel(room1c.y, room2c.y, room1c.x)
		carveHorTunnel(room1c.x, room2c.x, room2c.y)

func carveHorTunnel(x1, x2, y):
	for x in range(min(x1,x2),max(x1,x2)+1):
		level.set_cell(x, y, Tiles.DIRT)

func carveVirTunnel(y1, y2, x):
	for y in range(min(y1,y2),max(y1,y2)+1):
		level.set_cell(x, y, Tiles.DIRT)
