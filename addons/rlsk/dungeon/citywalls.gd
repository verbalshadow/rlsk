extends Dungeon

class_name CityWalls
"""
The City Walls algorithm is very similar to the BSP Tree
above. In fact their main difference is in how they generate
rooms after the actual tree has been created. Instead of 
starting with an array of solid walls and carving out
rooms connected by tunnels, the City Walls generator
starts with an array of floor tiles, then creates only the
exterior of the rooms, then opens one wall for a door.
"""

var room = null
export var MAX_LEAF_SIZE = 30
export var ROOM_MAX_SIZE = 28
export var ROOM_MIN_SIZE = 6
var rooms = []

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	# Creates an empty 2D array or clears existing array
	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.DIRT)

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
	createDoors()

	return level

func carveRoom(room):
	# Build Walls
	# set all tiles within a rectangle to 1
	for x in range(room.position.x + 1, room.end.x):
		for y in range(room.position.y + 1, room.end.y):
			level.set_cell(x, y, Tiles.WALL)
	# Build Interior
	for x in range(room.position.x + 2, room.end.x - 1):
		for y in range(room.position.y + 2, room.end.y - 1):
			level.set_cell(x, y, Tiles.BRICK)

func createDoors():
	for room in rooms:
		var roomCenter = center(room)


		var wallLoc = Vector2()
		var directions = ["north","south","east","west"]
		var wall = directions[randi() % directions.size()]
		if wall == "north":
			wallLoc.x = roomCenter.x
			wallLoc.y = room.position.y +1
		elif wall == "south":
			wallLoc.x = roomCenter.x
			wallLoc.y = room.end.y -1
		elif wall == "east":
			wallLoc.x = room.end.x -1
			wallLoc.y = roomCenter.y
		elif wall == "west":
			wallLoc.x = room.position.x +1
			wallLoc.y = roomCenter.y

		level.set_cellv(wallLoc, Tiles.BRICK)

func carveHall(room1, room2):
	# This method actually creates a list of rooms,
	# but since it is called from an outside class that is also
	# used by other dungeon Generators, it was simpler to 
	# repurpose the createHall method that to alter the leaf class.
	for room in [room1, room2]:
		if not room in rooms:
			rooms.append(room)
