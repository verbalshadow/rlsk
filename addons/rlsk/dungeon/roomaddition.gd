extends Dungeon

class_name RoomAddition
"""
What I'm calling the Room Addition algorithm is an attempt to 
recreate the dungeon generation algorithm used in Brogue, as
discussed at https://www.rockpapershotgun.com/2015/07/28/how-do-roguelikes-generate-levels/
I don't think Brian Walker has ever given a name to his
dungeon generation algorithm, so I've taken to calling it the 
Room Addition Algorithm, after the way in which it builds the 
dungeon by adding rooms one at a time to the existing dungeon.
This isn't a perfect recreation of Brian Walker's algorithm,
but I think it's good enough to demonstrait the concept.
"""

export var ROOM_MAX_SIZE = 18 # max height and width for cellular automata rooms
export var ROOM_MIN_SIZE = 16 # min size in number of floor tiles, not height and width
export var MAX_NUM_ROOMS = 30

export var SQUARE_ROOM_MAX_SIZE = 12
export var SQUARE_ROOM_MIN_SIZE = 6

export var CROSS_ROOM_MAX_SIZE = 12
export var CROSS_ROOM_MIN_SIZE = 6

export var cavernChance = 0.40 # probability that the first room will be a cavern
export var CAVERN_MAX_SIZE = 35 # max height an width

export var wallProbability = 0.45
export var neighbors = 4

export var squareRoomChance = 0.2
export var crossRoomChance = 0.15

export var buildRoomAttempts = 500
export var placeRoomAttempts = 20
export var maxTunnelLength = 12

export var includeShortcuts = true
export var shortcutAttempts = 500
export var shortcutLength = 5
export var minPathfindingDistance = 50

var rooms = []
var walkableList = []
var starMap = AStar.new()
var area = Vector2()

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.WALL)
	area = level.sizev()
#	randomize()
	# generate the first room
	var room = generateRoom()
	var roomSize = room.sizev()
	var roomX = int(mapWidth/2 - roomSize.x/2)-1
	var roomY = int(mapHeight/2 - roomSize.y/2)-1
	addRoom(roomX, roomY, room)

	# generate other rooms
	for i in range(buildRoomAttempts):
		room = generateRoom()
		# try to position the room, get roomX and roomY
		var info = placeRoom(room,mapWidth,mapHeight)
		if info.x and info.y:
			addRoom(info.x, info.y, room)
			addTunnel(info.wallTile, info.direction, info.tunnelLength)
			if len(rooms) >= MAX_NUM_ROOMS:
				break

	if includeShortcuts:
		addShortcuts(mapWidth, mapHeight)

	return level

func generateRoom():
	# select a room type to generate
	# generate and return that room
	var room
	if rooms:
		#There is at least one room already
		var choice = randf()

		if choice < squareRoomChance:
			room = generateRoomSquare()
		elif squareRoomChance <= choice and choice < (squareRoomChance+crossRoomChance):
			room = generateRoomCross() 
		else:
			room = generateRoomCellularAutomata()

	else: #it's the first room
		var choice = randf()
		if choice < cavernChance:
			room = generateRoomCavern()
		else:
			room = generateRoomSquare()

	return room

func generateRoomCross():
	var roomSize = range(CROSS_ROOM_MIN_SIZE+2,CROSS_ROOM_MAX_SIZE)
	var roomHorWidth = int((roomSize[randi() % roomSize.size()]))
	var roomVirHeight = int((roomSize[randi() % roomSize.size()]))
	var roomHHSize = range(CROSS_ROOM_MIN_SIZE,roomVirHeight)
	var roomHorHeight = int((roomHHSize[randi() % roomHHSize.size()]))
	var roomVWSize = range(CROSS_ROOM_MIN_SIZE,roomHorWidth)
	var roomVirWidth = int((roomVWSize[randi() % roomVWSize.size()]))

	var room = Array2D.new()
	room.resize(roomHorWidth, roomVirHeight)
	room.fill(Tiles.WALL)
	
	# Fill in horizontal space
	var virOffset = int(roomVirHeight/2) - int(roomHorHeight/2)
	for y in range(virOffset,roomHorHeight+virOffset):
		for x in range(0,roomHorWidth):
			room.set_cell(x, y, Tiles.DIRT)

	# Fill in vertical space
	var horOffset = int(roomHorWidth/2) - int(roomVirWidth/2)
	for y in range(0,roomVirHeight):
		for x in range(horOffset,roomVirWidth+horOffset):
			room.set_cell(x, y, Tiles.DIRT)

	return room

func generateRoomSquare():
	var roomWSize = range(SQUARE_ROOM_MIN_SIZE, SQUARE_ROOM_MAX_SIZE)
	var roomWidth = roomWSize[ randi() % roomWSize.size()]
	var roomHSize = range(max(int(roomWidth*0.5),SQUARE_ROOM_MIN_SIZE),min(int(roomWidth*1.5), SQUARE_ROOM_MAX_SIZE) )
	var roomHeight = roomHSize[ randi() % roomHSize.size()]

	var room = Array2D.new()
	room.resize(roomWidth, roomHeight)
	room.fill(Tiles.WALL)
	room.fillv( Vector2.ONE, Vector2(roomWidth-1, roomHeight-1), Tiles.DIRT)

	return room

func generateRoomCellularAutomata():
	while true:
		# if a room is too small, generate another
		var room = Array2D.new()
		room.resize(ROOM_MAX_SIZE, ROOM_MAX_SIZE)
		room.fill(Tiles.WALL)

		# random fill map
		for y in range(2,ROOM_MAX_SIZE-2):
			for x in range (2,ROOM_MAX_SIZE-2):
				if randf() >= wallProbability:
					room.set_cell(x, y, Tiles.DIRT)

		# create distinctive regions
		for i in range(4):
			for y in range (1,ROOM_MAX_SIZE-1):
				for x in range (1,ROOM_MAX_SIZE-1):
					# if the cell's neighboring walls > neighbors, set it to Tiles.WALL
					var adjTest = getAdjacentWalls(x,y,room)
					if adjTest > neighbors:
						room.set_cell(x, y, Tiles.WALL)
					# otherwise, set it to Tiles.DIRT
					elif adjTest < neighbors:
						room.set_cell(x, y, Tiles.DIRT)

		# floodfill to remove small caverns
		room = floodFill(room)

		# start over if the room is completely filled in
		var roomSize = room.sizev()
		for x in range (roomSize.x):
			for y in range (roomSize.y):
				if room.get_cell(x, y) == Tiles.DIRT:
					return room

func generateRoomCavern():
	while true:
		# if a room is too small, generate another
		var room = Array2D.new()
		room.resize(CAVERN_MAX_SIZE, CAVERN_MAX_SIZE)
		room.fill(Tiles.WALL)

		# random fill map
		for y in range (2,CAVERN_MAX_SIZE-2):
			for x in range (2,CAVERN_MAX_SIZE-2):
				if randf() >= wallProbability:
					room.set_cell(x, y, Tiles.DIRT)

		# create distinctive regions
		for i in range(4):
			for y in range (1,CAVERN_MAX_SIZE-1):
				for x in range (1,CAVERN_MAX_SIZE-1):

					# if the cell's neighboring walls > neighbors, set it to Tiles.WALL
					if getAdjacentWalls(x,y,room) > neighbors:
						room.set_cell(x, y, Tiles.WALL)
					# otherwise, set it to Tiles.DIRT
					elif getAdjacentWalls(x,y,room) < neighbors:
						room.set_cell(x, y, Tiles.DIRT)

		# floodfill to remove small caverns
		room = floodFill(room)

		# start over if the room is completely filled in
		var roomSize = room.sizev()
		for x in range (roomSize.x):
			for y in range (roomSize.y):
				if room.get_cell(x, y) == Tiles.DIRT:
					return room

func floodFill(room):
	"""
	Find the largest region. Fill in all other regions.
	"""
	var roomSize = room.sizev()
	var largestRegion = {} # dirty Set using dict keys

	for x in range (roomSize.x):
		for y in range (roomSize.y):
			if room.get_cell(x, y) == Tiles.DIRT:
				var newRegion = {} # dirty Set using dict keys
				var tile = Vector2(x,y)
				var toBeFilled = {}
				toBeFilled[tile] = null
				while toBeFilled:
					tile = toBeFilled.keys()[randi() % toBeFilled.size()]
					toBeFilled.erase(tile)
				
					if not tile in newRegion.keys():
						newRegion[tile] = null

						room.set_cell(tile.x, tile.y, Tiles.WALL)

						# check adjacent cells
						var north = Vector2(tile.x,tile.y-1)
						var south = Vector2(tile.x,tile.y+1)
						var east = Vector2(tile.x+1,tile.y)
						var west = Vector2(tile.x-1,tile.y)

						for direction in [north,south,east,west]:
							if room.get_cell(direction.x, direction.y) == Tiles.DIRT:
								if not direction in toBeFilled.keys() and not direction in newRegion.keys():
									toBeFilled[direction] = null

				if len(newRegion) >= ROOM_MIN_SIZE:
					if len(newRegion) > len(largestRegion):
#						largestRegion.clear()
						largestRegion = newRegion.duplicate(true)

	for tile in largestRegion.keys():
		room.set_cell(tile.x, tile.y, Tiles.DIRT)

	return room

func placeRoom(room, mapWidth, mapHeight): #(room,direction,)
	var roomX = null
	var roomY = null

	var roomSize = room.sizev()

	# try n times to find a wall that lets you build room in that direction
	for i in range(placeRoomAttempts):
		# try to place the room against the tile, else connected by a tunnel of length i

		var wallTile = null
		var direction = getDirection()
		while not wallTile:
			"""
			randomly select tiles until you find
			a wall that has another wall in the
			chosen direction and has a floor in the 
			opposite direction.
			"""
			#direction == tuple(dx,dy)
			var sizeW = range(1,mapWidth-2)
			var sizeH = range(1,mapHeight-2)
			var tileX = sizeW[randi() % sizeW.size()]
			var tileY = sizeH[randi() % sizeH.size()]
			if ((level.get_cell(tileX, tileY) == Tiles.WALL) and
				(level.get_cell(tileX+direction.x, tileY+direction.y) == Tiles.WALL) and
				(level.get_cell(tileX-direction.x, tileY-direction.y) == Tiles.DIRT)):
				wallTile = Vector2(tileX,tileY)

		#spawn the room touching wallTile
		var startRoomX = null
		var startRoomY = null
		"""
		TODO: replace this with a method that returns a 
		random floor tile instead of the top left floor tile
		"""
		while not startRoomX and not startRoomY:
			var xSize = range(0,roomSize.x-1)
			var ySize = range(0,roomSize.y-1)
			var x = xSize[randi() % xSize.size()]
			var y = ySize[randi() % ySize.size()]
			if room.get_cell(x, y) == Tiles.DIRT:
				startRoomX = wallTile.x - x
				startRoomY = wallTile.y - y

		#then slide it until it doesn't touch anything
		for tunnelLength in range(maxTunnelLength):
			var possibleRoomX = startRoomX + direction.x*tunnelLength
			var possibleRoomY = startRoomY + direction.y*tunnelLength

			var enoughRoom = getOverlap(room,possibleRoomX,possibleRoomY,mapWidth,mapHeight)

			if enoughRoom:
				roomX = possibleRoomX 
				roomY = possibleRoomY 

				return { "x": roomX, "y": roomY, "wallTile": wallTile, "direction": direction, "tunnelLength": tunnelLength}
	return { "x": null, "y": null, "wallTile": null, "direction": null, "tunnelLength": null}

func addRoom(roomX,roomY,room):
	var roomSize = room.sizev()
	for x in range (roomSize.x):
		for y in range (roomSize.y):
			if room.get_cell(x, y) == Tiles.DIRT:
				level.set_cell(int(roomX)+x, int(roomY)+y, Tiles.DIRT)
	rooms.append(room)

func addTunnel(wallTile,direction,tunnelLength):
	# carve a tunnel from a point in the room back to 
	# the wall tile that was used in its original placement

	var startX = wallTile.x + direction.x*tunnelLength
	var startY = wallTile.y + direction.y*tunnelLength
#	level.set_cell(startX, startY, Tiles.WALL)

	for i in range(maxTunnelLength):
		var x = startX - direction.x*i
		var y = startY - direction.y*i
		level.set_cell(x, y, Tiles.DIRT)
		# If you want doors, this is where the code should go
		if ((x+direction.x) == wallTile.x and 
			(y+direction.y) == wallTile.y):
			break

func getAdjacentWalls( tileX, tileY, room): # finds the walls in 8 directions
	var wallCounter = 0
	for x in range (tileX-1, tileX+2):
		for y in range (tileY-1, tileY+2):
			if (room.get_cell(x, y) == Tiles.WALL):
				if (x != tileX) or (y != tileY): # exclude (tileX,tileY)
					wallCounter += 1
	return wallCounter

func getDirection():
	# direction = (dx,dy)
	var north = Vector2(0,-1)
	var south = Vector2(0,1)
	var east = Vector2(1,0)
	var west = Vector2(-1,0)

	var options = [north,south,east,west]
	var direction = options[randi() % options.size()]
	return direction

func getOverlap(room,roomX,roomY,mapWidth,mapHeight):
	"""
	for each 0 in room, check the cooresponding tile in
	level and the eight tiles around it. Though slow,
	that should insure that there is a wall between each of
	the rooms created in this way.
	<> check for overlap with level
	<> check for out of bounds
	"""
	var roomSize = room.sizev()
	for x in range(roomSize.x):
		for y in range(roomSize.y):
			if room.get_cell(x, y) == Tiles.DIRT:
				# Check to see if the room is out of bounds
				if x + roomX in range(1, mapWidth-1) and y + roomY in range(1, mapHeight-1):
					#Check for overlap with a one tile buffer
					if level.get_cell(x+roomX-1, y+roomY-1) == Tiles.DIRT: # top left
						return false
					if level.get_cell(x+roomX, y+roomY-1) == Tiles.DIRT: # top center
						return false
					if level.get_cell(x+roomX+1, y+roomY-1) == Tiles.DIRT: # top right
						return false

					if level.get_cell(x+roomX-1, y+roomY) == Tiles.DIRT: # left
						return false
					if level.get_cell(x+roomX, y+roomY) == Tiles.DIRT: # center
						return false
					if level.get_cell(x+roomX+1, y+roomY) == Tiles.DIRT: # right
						return false																				

					if level.get_cell(x+roomX-1, y+roomY+1) == Tiles.DIRT: # bottom left
						return false
					if level.get_cell(x+roomX, y+roomY+1) == Tiles.DIRT: # bottom center
						return false
					if level.get_cell(x+roomX+1, y+roomY+1) == Tiles.DIRT: # bottom right
						return false							

				else: #room is out of bounds
					return false
	return true

func addShortcuts(mapWidth,mapHeight):
	"""
	Code in the python port used tcodpy builtin AStar. Switched to Godot's.
	"""

	#initialize the walkableList 
	makeWalkableList(mapWidth,mapHeight)

	var pathMap
	var path 
	var temp = 0
	for i in range(shortcutAttempts):
		# check i times for places where shortcuts can be made
		var floorX
		var floorY
		while true:
			#Pick a random floor tile
			var floorXSize = range(shortcutLength+1,(mapWidth-shortcutLength-1))
			var floorYSize = range(shortcutLength+1,(mapHeight-shortcutLength-1))
			floorX = floorXSize[randi() % floorXSize.size()]
			floorY = floorYSize[randi() % floorYSize.size()]
			if level.get_cell(floorX, floorY) == Tiles.DIRT: 
				if (level.get_cell(floorX-1, floorY) == Tiles.WALL or
					level.get_cell(floorX+1, floorY) == Tiles.WALL or
					level.get_cell(floorX, floorY-1) == Tiles.WALL or
					level.get_cell(floorX, floorY+1) == Tiles.WALL):
					break

		# look around the tile for other floor tiles
		for x in range(-1,2):
			for y in range(-1,2):
				if x != 0 or y != 0: # Exclude the center tile
					var newX = floorX + (x*shortcutLength)
					var newY = floorY + (y*shortcutLength)
					if level.get_cell(newX, newY) == Tiles.DIRT:
					# run pathfinding algorithm between the two points
						_add_traversable_tiles(walkableList)
						_connect_traversable_tiles(walkableList)
						path = get_path(Vector2(floorX,floorY), Vector2(newX,newY))
						var distance = path.size()

						if distance > minPathfindingDistance:
							# make shortcut
							carveShortcut(floorX,floorY,newX,newY)
	# destroy the path object
	starMap.clear()

func makeWalkableList(mapWidth,mapHeight):
	walkableList.clear()
	for cell in level.flatten():
		if cell.content == Tiles.DIRT:
			walkableList.append(cell.location)

func carveShortcut(x1,y1,x2,y2):
	var carvedSpots = []
	if x1-x2 == 0:
		# Carve vertical tunnel
		for y in range(min(y1,y2),max(y1,y2)+1):
			level.set_cell(x1, y, Tiles.DIRT)
			carvedSpots.append(Vector2(x1,y))

	elif y1-y2 == 0:
		# Carve Horizontal tunnel
		for x in range(min(x1,x2),max(x1,x2)+1):
			level.set_cell(x, y1, Tiles.DIRT)
			carvedSpots.append(Vector2(x,y1))

	elif (y1-y2)/(x1-x2) == 1:
		# Carve NW to SE Tunnel
		var x = min(x1,x2)
		var y = min(y1,y2)
		while x != max(x1,x2):
			x+=1
			level.set_cell(x, y, Tiles.DIRT)
			carvedSpots.append(Vector2(x,y))
			y+=1
			level.set_cell(x, y, Tiles.DIRT)
			carvedSpots.append(Vector2(x,y))

	elif (y1-y2)/(x1-x2) == -1:
		# Carve NE to SW Tunnel
		var x = min(x1,x2)
		var y = max(y1,y2)
		while x != max(x1,x2):
			x += 1
			level.set_cell(x, y, Tiles.DIRT)
			carvedSpots.append(Vector2(x,y))
			y -= 1
			level.set_cell(x, y, Tiles.DIRT)
			carvedSpots.append(Vector2(x,y))
	walkableList = carvedSpots

func checkRoomExists(room):
	var roomSize = room.sizev()
	for x in range(roomSize.x):
		for y in range(roomSize.y):
			if room.get_cell(x, y) == Tiles.DIRT:
				return true
	return false

# Adds tiles to the A* grid but does not connect them
# ie. They will exist on the grid, but you cannot find a path yet
func _add_traversable_tiles(traversable_tiles):

	# Loop over all tiles
	for tile in traversable_tiles:

		# Determine the ID of the tile
		var id = _get_id_for_point(tile)

		# Add the tile to the starMap navigation
		# NOTE: We use Vector3 as starMap is, internally, 3D. We just don't use Z.
		starMap.add_point(id, Vector3(tile.x, tile.y, 0))


# Connects all tiles on the A* grid with their surrounding tiles
func _connect_traversable_tiles(traversable_tiles):
	for point in traversable_tiles:
		var point_index = _get_id_for_point(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstalce,
		# We connect the current point with it
		var points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index = _get_id_for_point(point_relative)

#			if is_outside_map_bounds(point_relative):
#				continue
			if not starMap.has_point(point_relative_index):
				continue
			# Note the 3rd argument. It tells the starMap that we want the
			# connection to be bilateral: from point A to B and B to A
			# If you set this value to false, it becomes a one-way path
			# As we loop through all points we can set it to false
			starMap.connect_points(point_index, point_relative_index, true)


# Determines a unique ID for a given point on the map
func _get_id_for_point(point):
	# Returns the unique ID for the point on the map
	return point.x + area.x * point.y


## Public functions

# Returns a path from start to end
# These are real positions, not cell coordinates
func get_path(start, end):

	# Determines IDs
	var start_id = _get_id_for_point(start)
	var end_id = _get_id_for_point(end)

	# Return null if navigation is impossible
	if not starMap.has_point(start_id) or not starMap.has_point(end_id):
		return null

	# Otherwise, find the map
	var path_map = starMap.get_point_path(start_id, end_id)
	return path_map
