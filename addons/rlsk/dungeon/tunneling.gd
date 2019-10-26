extends Dungeon

class_name Tunneling

"""
This version of the tunneling algorithm is essentially
identical to the tunneling algorithm in the Complete Roguelike
Tutorial using Python, which can be found at
http://www.roguebasin.com/index.php?title=Complete_Roguelike_Tutorial,_using_python%2Btcod,_part_1

Requires random.randint() and the Rect class defined below.
"""


export var ROOM_MAX_SIZE := 15
export var ROOM_MIN_SIZE := 6
export var MAX_ROOMS := 30

func generateLevel(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT):
	# Creates an empty 2D array or clears existing array
	level.resize(mapWidth, mapHeight)
	level.fill(Tiles.WALL)
	
	var rooms = []
	var num_rooms = 0

	for r in range(MAX_ROOMS):
		# random width and height
		var room_size = range(ROOM_MIN_SIZE,ROOM_MAX_SIZE)
		var w = room_size[randi() % room_size.size()]
		var h = room_size[randi() % room_size.size()]
		# random position within map boundries
		var x = randi() % (MAP_WIDTH - w)
		var y = randi() % (MAP_HEIGHT - h)

		var new_room = Rect2(x, y, w, h)
		# check for overlap with previous rooms
		var failed = false
		for other_room in rooms:
			if new_room.intersects(other_room):
				failed = true
				break

		if not failed:
			createRoom(new_room)
			var new = center(new_room)

			if num_rooms != 0:
				# all rooms after the first one
				# connect to the previous room

				#center coordinates of the previous room
				var prev = center(rooms[num_rooms-1])

				# 50% chance that a tunnel will start horizontally
				if randi() % 2:
					createHorTunnel(prev.x, new.x, prev.y)
					createVirTunnel(prev.y, new.y, new.x)

				else: # else it starts virtically
					createVirTunnel(prev.y, new.y, prev.x)
					createHorTunnel(prev.x, new.x, new.y)

			# append the new room to the list
			rooms.append(new_room)
			num_rooms += 1



	return level

func createRoom(room):
	# set all tiles within a rectangle to 0
	for x in range(room.position.x + 1, room.end.x):
		for y in range(room.position.y + 1, room.end.y):
			level.set_cell(x, y, Tiles.BRICK)

func createHorTunnel(x1, x2, y):
	for x in range(int(min(x1,x2)),int(max(x1,x2)) + 1):
		level.set_cell(x, y, Tiles.BRICK)

func createVirTunnel(y1, y2, x):
	for y in range(int(min(y1,y2)),int(max(y1,y2)) + 1):
		level.set_cell(x, y, Tiles.BRICK)
