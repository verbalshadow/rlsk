extends Dungeon

class_name DrunkardsWalk

export var  _percentGoal := 0.4
export var walkIterations := 25000 # cut off in case _percentGoal in never reached
export var weightedTowardCenter := 0.15
export var weightedTowardPreviousDirection := 0.7

var drunkard = Vector2()
var _previousDirection = null
var _filled = 0

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	# Creates an empty 2D array or clears existing array
	walkIterations = max(walkIterations, (mapWidth*mapHeight*10))
	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.WALL)

	drunkard.x = randi() % (mapWidth-2) + 2
	drunkard.y = randi() % (mapHeight-2) + 2
	var filledGoal = mapWidth*mapHeight*_percentGoal

	for i in range(walkIterations):
		walk(mapWidth, mapHeight)
		if (_filled >= filledGoal):
			break

	return level

func walk(mapWidth, mapHeight):
	# ==== Choose Direction ====
	var north = 1.0
	var south = 1.0
	var east = 1.0
	var west = 1.0

	# weight the random walk against edges
	if drunkard.x < mapWidth*0.25: # drunkard is at far left side of map
		east += weightedTowardCenter
	elif drunkard.x > mapWidth*0.75: # drunkard is at far right side of map
		west += weightedTowardCenter
	if drunkard.y < mapHeight*0.25: # drunkard is at the top of the map
		south += weightedTowardCenter
	elif drunkard.y > mapHeight*0.75: # drunkard is at the bottom of the map
		north += weightedTowardCenter

	# weight the random walk in favor of the previous direction
	if _previousDirection == "north":
		north += weightedTowardPreviousDirection
	if _previousDirection == "south":
		south += weightedTowardPreviousDirection
	if _previousDirection == "east":
		east += weightedTowardPreviousDirection
	if _previousDirection == "west":
		west += weightedTowardPreviousDirection

	# normalize probabilities so they form a range from 0 to 1
	var total = north+south+east+west

	north /= total
	south /= total
	east /= total
	west /= total

	# choose the direction
	var choice = randf()
	var d = Vector2()
	var direction
	
	if 0 <= choice and choice < north:
		d.x = 0
		d.y = -1
		direction = "north"
	elif north <= choice and choice < (north+south):
		d.x = 0
		d.y = 1
		direction = "south"
	elif (north+south) <= choice and choice < (north+south+east):
		d.x = 1
		d.y = 0
		direction = "east"
	else:
		d.x = -1
		d.y = 0
		direction = "west"

	# ==== Walk ====
	# check colision at edges TODO: change so it stops one tile from edge
	if drunkard.x+d.x in range(1, mapWidth-1) and drunkard.y+d.y in range(1, mapHeight-1):
		drunkard += d
		if level.get_cellv(drunkard) == Tiles.WALL:
			level.set_cellv(drunkard, Tiles.BRICK)
			_filled += 1
		_previousDirection = direction