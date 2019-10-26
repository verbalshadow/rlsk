extends Dungeon

class_name MessyBSPTree
"""
A Binary Space Partition connected by a severely weighted
drunkards walk algorithm.
Requires Leaf and Rect classes.
"""

var room = null
export var MAX_LEAF_SIZE = 24
export var ROOM_MAX_SIZE = 15
export var ROOM_MIN_SIZE = 6
export var smoothEdges = true
export var smoothing = 1
export var filling = 3

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
	cleanUpMap(mapWidth,mapHeight)

	return level

func carveRoom(room):
	# set all tiles within a rectangle to 0
	for x in range(room.position.x + 1, room.end.x):
		for y in range(room.position.y+1, room.end.y):
			level.set_cell(x, y , Tiles.DIRT)

func carveHall(room1, room2):
	# run a heavily weighted random Walk 
	# from point2 to point1
	var drunkard = center(room2)
	var goal = center(room1)
	while not drunkard.x in range(room1.position.x, room1.end.x) or not drunkard.y in range(room1.position.y, room1.end.y): #
		# ==== Choose Direction ====
		var north = 1.0
		var south = 1.0
		var east = 1.0
		var west = 1.0

		var weight = 1

		# weight the random walk against edges
		if drunkard.x < goal.x: # drunkard is left of point1
			east += weight
		elif drunkard.x > goal.x: # drunkard is right of point1
			west += weight
		if drunkard.y < goal.y: # drunkard is above point1
			south += weight
		elif drunkard.y > goal.y: # drunkard is below point1
			north += weight

		# normalize probabilities so they form a range from 0 to 1
		var total = north+south+east+west
		north /= total
		south /= total
		east /= total
		west /= total

		# choose the direction
		var choice = randf()
		var d = Vector2()
		
		if 0 <= choice and choice < north:
			d.x = 0
			d.y = -1
		elif north <= choice and choice < (north+south):
			d.x = 0
			d.y = 1
		elif (north+south) <= choice and choice < (north+south+east):
			d.x = 1
			d.y = 0
		else:
			d.x = -1
			d.y = 0

		# ==== Walk ====
		# check colision at edges
		if drunkard.x+d.x in range(0,  MAP_WIDTH-1) and drunkard.y+d.y in range (0, MAP_HEIGHT-1):
			drunkard.x += d.x
			drunkard.y += d.y
			if level.get_cellv(drunkard) == Tiles.WALL:
				level.set_cellv(drunkard, Tiles.DIRT)

func cleanUpMap(mapWidth,mapHeight):
	if (smoothEdges):
		for i in range (3):
			# Look at each cell individually and check for smoothness
			for x in range(1,mapWidth-1):
				for y in range (1,mapHeight-1):
					if level.get_cell(x, y) == Tiles.WALL and (getAdjacentWallsSimple(x,y) <= smoothing):
						level.set_cell(x, y, Tiles.DIRT)

					if level.get_cell(x, y) == Tiles.DIRT and (getAdjacentWallsSimple(x,y) >= filling):
						level.set_cell(x, y, Tiles.WALL)

func getAdjacentWallsSimple(x, y): # finds the walls in four directions
	var wallCounter = 0
	#print("(",x,",",y,") = ",level[x][y])
	if level.get_cell(x, y-1) == Tiles.WALL: # Check north
		wallCounter += 1
	if level.get_cell(x, y+1) == Tiles.WALL: # Check south
		wallCounter += 1
	if level.get_cell(x-1, y) == Tiles.WALL: # Check west
		wallCounter += 1
	if level.get_cell(x+1, y) == Tiles.WALL: # Check east
		wallCounter += 1

	return wallCounter
