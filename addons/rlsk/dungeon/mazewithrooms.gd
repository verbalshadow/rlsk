extends Dungeon

class_name MazeWithRooms
"""
Python implimentation of the rooms and mazes algorithm found at
http://journal.stuffwithstuff.com/2014/12/21/rooms-and-mazes/
by Bob Nystrom
"""
export var ROOM_MAX_SIZE = 13
export var ROOM_MIN_SIZE = 6


export var buildRoomAttempts = 100
export var connectionChance = 0.04
export var windingPercent = 0.1
export var allowDeadEnds = false
export var useCleanDistance = true
export var connectorCleanDistance = 6

var _regions = Array2D.new()
var north = Vector2.UP
var south = Vector2.DOWN
var east = Vector2.RIGHT
var west = Vector2.LEFT
var _currentRegion = -1 # the index of the current region in _regions

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	# Creates an empty 2D array or clears existing array

	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.WALL)
	
	if (mapWidth % 2 == 0): mapWidth -= 1
	if (mapHeight % 2 == 0): mapHeight -= 1

	_regions.resize(mapWidth, mapHeight)
	_regions.fill(null)


	addRooms(mapWidth,mapHeight)#?

	# Fill in the empty space around the rooms with mazes
	for x in range(1,mapWidth,2):
		for y in range (1,mapHeight,2):
			if level.get_cell(x, y) != Tiles.WALL:
				continue
			var start = Vector2(x,y)
			growMaze(start,mapWidth,mapHeight)

	connectRegions(mapWidth,mapHeight)

	if not allowDeadEnds: 
		removeDeadEnds(mapWidth,mapHeight)

	return level

func growMaze(start,mapWidth,mapHeight):

	var cells = []
	var lastDirection = null

	startRegion()
	carve(start[0],start[1])

	cells.append(start)

	while cells:
		var cell = cells[-1]

		# see if any adjacent cells are open
		var unmadeCells = {} # dirty Set using dict keys

		for direction in [north,south,east,west]:
			if canCarve(cell,direction,mapWidth,mapHeight):
				unmadeCells[direction] = null

		if (unmadeCells):
			"""
			Prefer to carve in the same direction, when
			it isn't necessary to do otherwise.
			"""
			var direction
			
			if ((lastDirection in unmadeCells) and
				(randf() > windingPercent)):
				direction = lastDirection
			else:
				direction = unmadeCells.keys().pop_front()
				unmadeCells.erase(direction)

			var newCell = cell + direction
			carve(newCell.x,newCell.y)

			newCell = Vector2((cell.x+direction.x*2),(cell.y+direction.y*2))
			carve(newCell.x,newCell.y)
			cells.append(newCell)

			lastDirection = direction

		else:
			# No adjacent uncarved cells
			cells.pop_front()
			lastDirection = null

func addRooms(mapHeight,mapWidth):
	var rooms = []
	var roomSize = range(int(ROOM_MIN_SIZE/2),int(ROOM_MAX_SIZE/2))
	for i in range(buildRoomAttempts):

		"""
		Pick a random room size and ensure that rooms have odd 
		dimensions and that rooms are not too narrow.
		"""
		var roomWidth = roomSize[randi() % roomSize.size()] * 2 + 1
		var roomHeight = roomSize[randi() % roomSize.size()] * 2 + 1
		var xSize = range(0, mapWidth-roomWidth-1)
		var ySize = range(0, mapHeight-roomHeight-1)
		var x = (xSize[randi() % xSize.size()]/2) * 2 + 1
		var y = (ySize[randi() % ySize.size()]/2) * 2 + 1
		
		var room = Rect2(x,y,roomWidth,roomHeight)
		# check for overlap with previous rooms
		var failed = false
		for otherRoom in rooms:
			if room.intersects(otherRoom):
				failed = true
				break

		if not failed:
			rooms.append(room)

			startRegion()
			createRoom(room)

func connectRegions(mapWidth,mapHeight):
	# Find all of the tiles that can connect two regions

	var connectorRegions = Array2D.new()
	connectorRegions.resize(mapWidth, mapHeight)
	connectorRegions.fill(null)

	for x in range(1,mapWidth-1):
		for y in range(1,mapHeight-1):
			if level.get_cell(x, y) != Tiles.WALL: continue

			# count the number of different regions the wall tile is touching
			var regionsInArea = {} # dirty Set using dict keys
			for direction in [north,south,east,west]:
				var new = Vector2(x + direction.x, y + direction.y)
				var region = _regions.get_cellv(new)
				if region != null: 
					regionsInArea[region] = null
			if regionsInArea.size() < 2: continue
			# The wall tile touches at least two regions
			connectorRegions.set_cell(x, y, regionsInArea)

	# make a list of all of the connectors
	var connectors = {} # dirty Set using dict keys
	for x in range(0,mapWidth):
		for y in range(0,mapHeight):
			if connectorRegions.get_cell(x, y) != null:
				var connectorPosition = Vector2(x,y)
				connectors[connectorPosition] = null

	# keep track of the regions that have been merged.
	var merged = {}
	var openRegions = {} # dirty Set using dict keys
	for i in range(_currentRegion+1):
		merged[i] = i
		openRegions[i] = null

	# connect the regions
	while len(openRegions) > 1: # and len(connectors) > 1
		# get random connector
		var connector = connectors.keys()[randi() % connectors.size()]
		# carve the connection
		addJunction(connector)

		# merge the connected regions
		# make a list of the regions at (x,y)
		var regionsAtSpot = connectorRegions.get_cellv(connector).keys()

		var dest = regionsAtSpot.front()
		var sources = regionsAtSpot.duplicate(true)
		sources.pop_front()

		"""
		Merge all of the effective regions. You must look
		at all of the regions, as some regions may have
		previously been merged with the ones we are
		connecting now.
		"""
		for i in range(_currentRegion+1):
			if merged[i] in sources:
				merged[i] = dest

		# clear the sources, they are no longer needed
		for s in sources:
			if s in openRegions.keys():
				openRegions.erase(s)

		# remove the unneeded connectors
		var toBeRemoved = {} # dirty Set using dict keys
		if useCleanDistance:
			for pos in connectors:
				# remove connectors that are next to the current connector
				if connector.distance_to(pos) < connectorCleanDistance :
					# remove it
					toBeRemoved[pos] = null
					continue
	
				var regions = {} # dirty Set using dict keys
	
				for n in connectorRegions.get_cellv(pos):
					var actualRegion = merged[n]
					regions[actualRegion] = null
				if len(regions) > 1: 
					continue
	
				if randf() < connectionChance:
					addJunction(pos)
	
				# remove it
				if len(regions) == 1:
					toBeRemoved[pos] = null
		else:
			for pos in connectorRegions.flatten():
#				for con in place.content:
				if pos.content == null: 
					continue
				if pos.content.has_all(regionsAtSpot) and regionsAtSpot.size() == pos.content.size():
						toBeRemoved[pos.location] = null
	
				var regions = {} # dirty Set using dict keys
	
				for n in connectorRegions.get_cellv(pos.location):
					var actualRegion = merged[n]
					regions[actualRegion] = null
				if len(regions) > 1: 
					continue
	
				if randf() < connectionChance:
					addJunction(pos.location)
	
				# remove it
				if len(regions) == 1:
					toBeRemoved[pos.location] = null
					
		connectors = difference_update(connectors, toBeRemoved)
		if  connectors.size() == 0:
			openRegions.clear()

func createRoom(room):
	# set all tiles within a rectangle to 0
	level.fillv(room.position, room.end, Tiles.DIRT)
	_regions.fillv(room.position, room.end, _currentRegion)
#	for x in range(int(room.size.x)):
#		for y in range(int(room.size.y)):
#			carve(x,y)

func addJunction(pos):
	level.set_cellv(pos, Tiles.DIRT)

func removeDeadEnds(mapWidth,mapHeight):
	var done = false

	while not done:
		done = true

		for y in range(1,mapHeight):
			for x in range(1,mapWidth):
				if level.get_cell(x, y) == Tiles.DIRT:

					var exits = 0
					for direction in [north,south,east,west]:
						if level.get_cell(x+direction.x, y+direction.y) == Tiles.DIRT:
							exits += 1
					if exits > 1: continue

					done = false
					level.set_cell(x, y, Tiles.WALL)

func canCarve(pos,dir,mapWidth,mapHeight):
	"""
	gets whether an opening can be carved at the location
	adjacent to the cell at (pos) in the (dir) direction.
	returns false if the location is out of bounds or if the cell
	is already open.
	"""
	var x = pos.x+dir.x*3
	var y = pos.y+dir.y*3

	if not x in range(0, mapWidth) or not y in range(0, mapHeight):
		return false

	x = pos.x+dir.x*2
	y = pos.y+dir.y*2

	# return true if the cell is a wall (1)
	# false if the cell is a floor (0)
	return (level.get_cell(x, y) == Tiles.WALL)

#func distance(point1,point2):
#	d = sqrt((point1[0]-point2[0])**2 + (point1[1]-point2[1])**2)
#	return d

func startRegion():
	_currentRegion += 1

func carve(x,y):
	level.set_cell(x, y, Tiles.DIRT)
	_regions.set_cell(x, y, _currentRegion)

func difference_update(list : Dictionary, remove : Dictionary):
	var realList = list.duplicate(true)
	if remove.size() == 0:
		return list
	for item in remove.keys():
		if realList.has(item):
			var test = realList.erase(item)
	return realList