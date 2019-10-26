extends Reference

class_name Leaf # used for the BSP tree algorithm
#func __init__(x, y, width, height):
	
var x 
var y 
var width 
var height 
export var MIN_LEAF_SIZE = 10
var child_1 = null
var child_2 = null
var room := Rect2()
var hall = null

func splitLeaf():
	# begin splitting the leaf into two children
	if (child_1 != null) or (child_2 != null):
		return false # This leaf has already been split

	"""
	==== Determine the direction of the split ====
	If the width of the leaf is >25% larger than the height,
	split the leaf vertically.
	If the height of the leaf is >25 larger than the width,
	split the leaf horizontally.
	Otherwise, choose the direction at random.
	"""
	var splitHorizontally = randi() % 2
	if (width/height >= 1.25):
		splitHorizontally = false
	elif (height/width >= 1.25):
		splitHorizontally = true

	var maxSize
	if (splitHorizontally):
		maxSize = height - MIN_LEAF_SIZE
	else:
		maxSize = width - MIN_LEAF_SIZE

	if (maxSize <= MIN_LEAF_SIZE):
		return false # the leaf is too small to split further

	var leafRange = range(MIN_LEAF_SIZE,maxSize)
	var split = leafRange[randi() % leafRange.size()] #determine where to split the leaf

	if (splitHorizontally): # using get_script() to avoid recursive class issue
		child_1 = get_script().new(x, y, width, split)
		child_2 = get_script().new(x, y+split, width, height-split)
	else:
		child_1 = get_script().new(x, y,split, height)
		child_2 = get_script().new(x + split, y, width-split, height)

	return true

func createRooms(bspTree):
	if (child_1) or (child_2):
		# recursively search for children until you hit the end of the branch
		if (child_1):
			child_1.createRooms(bspTree)
		if (child_2):
			child_2.createRooms(bspTree)

		if (child_1 and child_2):
			bspTree.carveHall(child_1.getRoom(), child_2.getRoom())

	else:
	# Create rooms in the end branches of the bsp tree
		var wRange = range(bspTree.ROOM_MIN_SIZE, min(bspTree.ROOM_MAX_SIZE,width-1))
		var hRange = range(bspTree.ROOM_MIN_SIZE, min(bspTree.ROOM_MAX_SIZE,height-1))
		var w = wRange[randi() % wRange.size()] 
		var h = hRange[randi() % hRange.size()] 
		var xRange = range(x, x+(width-1)-w)
		var yRange = range(y, y+(height-1)-h)
		var x = xRange[randi() % xRange.size()] 
		var y = yRange[randi() % yRange.size()] 
		room = Rect2(x,y,w,h)
		bspTree.carveRoom(room)

func getRoom():
	var room_1
	var room_2
	if (room): 
		return room
	else:
		if (child_1):
			room_1 = child_1.getRoom()
		if (child_2):
			room_2 = child_2.getRoom()

		if (not child_1 and not child_2):
			# neither room_1 nor room_2
			return null

		elif (not room_2):
			# room_1 and !room_2
			return room_1

		elif (not room_1):
			# room_2 and !room_1
			return room_2

		# If both room_1 and room_2 exist, pick one
		elif (randf() < 0.5):
			return room_1
		else:
			return room_2

func _init(newX := 0, newY := 0, newWidth := 0, newHeight := 0) -> void:
	x = newX
	y = newY
	width = newWidth
	height = newHeight
	