extends Dungeon

class_name CellularAutomata

"""
Rather than implement a traditional cellular automata, I 
decided to try my hand at a method discribed by "Evil
Scientist" Andy Stobirski that I recently learned about
on the Grid Sage Games blog.
"""

export var iterations = 30000
export var neighbors = 4 # number of neighboring walls for this cell to become a wall
export var wallProbability = 0.50 # the initial probability of a cell becoming a wall, recommended to be between .35 and .55

export var ROOM_MIN_SIZE = 16 # size in total number of cells, not dimensions
export var ROOM_MAX_SIZE = 500 # size in total number of cells, not dimensions

export var smoothEdges = true
export var smoothing =  1
var caves = []

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	# Creates an empty 2D array or clears existing array

	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.WALL)

	randomFillMap(mapWidth,mapHeight)
	createCaves(mapWidth,mapHeight)
	getCaves(mapWidth,mapHeight)
	connectCaves(mapWidth,mapHeight)
	cleanUpMap(mapWidth,mapHeight)
	return level

func randomFillMap(mapWidth,mapHeight):
	for y in range (1,mapHeight-1):
		for x in range (1,mapWidth-1):
			#print("(",x,y,") = ",level[x][y])
			if randf() >= wallProbability:
				level.set_cell(x, y, Tiles.DIRT)

func createCaves(mapWidth,mapHeight):
	# ==== Create distinct caves ====
	for i in range (0,iterations):
		# Pick a random point with a buffer around the edges of the map
		var size_x = range(1, mapWidth-2) #(2,mapWidth-3)
		var size_y = range(1, mapHeight-2) #(2,mapHeight-3)
		var tile = Vector2(size_x[randi() % size_x.size()], size_y[randi() % size_y.size()])

		# if the cell's neighboring walls > neighbors, set it to 1
		if getAdjacentWalls(tile.x,tile.y) > neighbors:
			level.set_cellv(tile, Tiles.WALL)
		# or set it to 0
		elif getAdjacentWalls(tile.x,tile.y) < neighbors:
			level.set_cellv(tile, Tiles.DIRT)

	# ==== Clean Up Map ====
	cleanUpMap(mapWidth,mapHeight)

func cleanUpMap(mapWidth,mapHeight):
	if (smoothEdges):
		for i in range (0,5):
			# Look at each cell individually and check for smoothness
			for x in range(1,mapWidth-2):
				for y in range (1,mapHeight-2):
					if (level.get_cell(x, y) == Tiles.WALL) and (getAdjacentWallsSimple(x,y) <= smoothing):
						level.set_cell(x, y, Tiles.DIRT)

func createTunnel(point1,point2,currentCave,mapWidth,mapHeight):
	# run a heavily weighted random Walk 
	# from point1 to point1
	var drunkard = point2
	while not Vector2(drunkard.x,drunkard.y) in currentCave:
		# ==== Choose Direction ====
		var north = 1.0
		var south = 1.0
		var east = 1.0
		var west = 1.0

		var weight = 1

		# weight the random walk against edges
		if drunkard.x < point1.x: # drunkard is left of point1
			east += weight
		elif drunkard.x > point1.x: # drunkard is right of point1
			west += weight
		if drunkard.y < point1.y: # drunkard is above point1
			south += weight
		elif drunkard.y > point1.y: # drunkard is below point1
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
		if drunkard.x+d.x in range(0, mapWidth-1) and drunkard.y+d.y in range(0, mapHeight-1):
			drunkard.x += d.x
			drunkard.y += d.y
			if level.get_cell(drunkard.x, drunkard.y) == Tiles.WALL:
				level.set_cell(drunkard.x, drunkard.y, Tiles.DIRT)

func getAdjacentWallsSimple(x, y): # finds the walls in four directions
	var wallCounter = 0
	#print("(",x,",",y,") = ",level[x][y])
	if (level.get_cell(x, y-1) == Tiles.WALL): # Check north
		wallCounter += 1
	if (level.get_cell(x, y+1) == Tiles.WALL): # Check south
		wallCounter += 1
	if (level.get_cell(x-1, y) == Tiles.WALL): # Check west
		wallCounter += 1
	if (level.get_cell(x+1, y) == Tiles.WALL): # Check east
		wallCounter += 1

	return wallCounter

func getAdjacentWalls(tileX, tileY): # finds the walls in 8 directions
	pass
	var wallCounter = 0
	for x in range (tileX-1, tileX+2):
		for y in range (tileY-1, tileY+2):
			if (level.get_cell(x, y) == Tiles.WALL):
				if (x != tileX) or (y != tileY): # exclude (tileX,tileY)
					wallCounter += 1
	return wallCounter

func getCaves(mapWidth, mapHeight):
	# locate all the caves within level and store them in caves
	for x in range (1,mapWidth -1):
		for y in range (1,mapHeight -1):
			if level.get_cell(x, y) == Tiles.DIRT:
				floodFill(x,y)

	for set in caves:
		for tile in set:
			level.set_cellv(tile, Tiles.DIRT)


func floodFill(x,y):
	"""
	flood fill the separate regions of the level, discard
	the regions that are smaller than a minimum size, and 
	create a reference for the rest.
	"""
	var cave = {} # dirty Set using dict keys
	var tile = Vector2(x,y)
	var toBeFilled = {} # dirty Set using dict keys
	toBeFilled[tile] = null
	while toBeFilled:
		var new_tile = toBeFilled.keys()[randi() % toBeFilled.size()]
		toBeFilled.erase(new_tile)
		
		if not new_tile in cave.keys():
			cave[new_tile] = null
			
			level.set_cellv(new_tile, Tiles.WALL)
			
			#check adjacent cells
			var north =  new_tile + Vector2.UP
			var south = new_tile + Vector2.DOWN
			var east = new_tile + Vector2.RIGHT
			var west = new_tile + Vector2.LEFT
			
			for direction in [north,south,east,west]:

				if level.get_cellv(direction) == Tiles.DIRT:
					if not direction in toBeFilled.keys() and not direction in cave.keys():
						toBeFilled[direction] = null

	if len(cave) >= ROOM_MIN_SIZE:
		caves.append(cave)

func connectCaves(mapWidth, mapHeight):
	# Find the closest cave to the current cave
	for currentCave in caves:
		var point1 = currentCave.keys()[randi() % currentCave.size()] # get an element from cave1
		var point2 = null
		var distance = null
		for nextCave in caves:
			if nextCave != currentCave and not checkConnectivity(currentCave,nextCave):
				# choose a random point from nextCave
				var nextPoint = nextCave.keys()[randi() % nextCave.size()]
				# compare distance of point1 to old and new point2
				var newDistance = point1.distance_to(nextPoint)
				if distance == null or (newDistance < distance):
					point2 = nextPoint
					distance = newDistance

		if point2: # if all tunnels are connected, point2 == null
			createTunnel(point1,point2,currentCave,mapWidth,mapHeight)

func checkConnectivity(cave1,cave2):
	# floods cave1, then checks a point in cave2 for the flood

	var connectedRegion = {} # dirty Set using dict keys
	var start = cave1.keys()[randi() % cave1.size()] # get an element from cave1
	
	var toBeFilled = {} # dirty Set using dict keys
	toBeFilled[start] = null
	while toBeFilled:
		var tile = toBeFilled.keys()[randi() % toBeFilled.size()]
		toBeFilled.erase(tile)

		if not tile in connectedRegion:
			connectedRegion[tile] = null

			#check adjacent cells
			var north =  tile + Vector2.UP
			var south = tile + Vector2.DOWN
			var east = tile + Vector2.RIGHT
			var west = tile + Vector2.LEFT

			for direction in [north,south,east,west]:

				if level.get_cellv(direction) == Tiles.DIRT:
					if not direction in toBeFilled.keys() and not direction in connectedRegion.keys():
						toBeFilled[direction] = null

	var end = cave2.keys()[randi() % cave2.size()] # get an element from cave2

	if end in connectedRegion.keys(): return true

	else: return false
