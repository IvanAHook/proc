level = {}
level.w = 20
level.h = 20
--level.rooms = ""

maxRoomSize = 5
minRoomSize = 3
corridorLength = 5

rooms = {}
corridors = {}

math.randomseed(os.time())

function createRoom(x, y, w, h)
  local room = {}
  room.x = x
  room.y = y
  room.w = w
  room.h = h
  
  --room.doorTile = selectRandomWallTile(room)
  return room
end

function createRandomRoom()
  x = math.random(1, level.w)
  y = math.random(1, level.h)
  w = math.random(minRoomSize, maxRoomSize)
  h = math.random(minRoomSize, maxRoomSize)
  --insert in level.rooms
  local room = createRoom(x, y, w, h)
  room.doorTile = selectRandomWallTile(room)
  return room
end

function createCorridor(x, y, lenght)
  local corridor = {}
  corridor.x = x
  corridor.y = y
  corridor.lenght = lenght
  return corridor
end

--function roomCenter(room) 
--  local center = {}
--  center.x = room.x + room.width / 2
--  center.y = room.y + room.height / 2
--  return center
--end


function roomOverlaps(room1, room2)
  return room1.x <= room2.x+room2.w and room1.x+room1.w >= room2.x and room1.y <= room2.y+room2.h and room1.y+room1.h >= room2.y
end

function selectRandomWallTile(room)
  local tiles = {}
  for y = room.y, room.y + room.h do
    for x = room.x, room.x + room.w do
      
      -- dont want the dor to be in any of the rooms corners
      if y == room.y and x == room.x
      or y == room.y and x == room.x + room.w
      or y == room.y + room.h and x == room.x
      or y == room.y + room.h and x == room.x + room.w then
        goto continue
      end
      
      -- add all remaining wall tiles
      if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then
        local tile = {}
        tile.x = x
        tile.y = y
        table.insert(tiles, tile)
      end
      ::continue::
    end
    
  end
  
  local considerTile
  local result = false
  while result == false do
    --check if there is room in this direction
    considerTile = tiles[math.random(1, #tiles)]
    local direction -- 1 = up, 2 = down, 3 = left, 4 = right
    if considerTile.y == room.y then direction = 1 end
    if considerTile.y == room.y + room.h then direction = 2 end
    if considerTile.x == room.x then direction = 3 end
    if considerTile.x == room.x + room.w then direction = 4 end
    
    print("direction: " .. direction)
    
    if direction == 1 then
      local testArea = createRoom(considerTile.x-1, considerTile.y-corridorLength, 3, corridorLength)
      print(testArea.x .. " " .. testArea.y)
      if validateRoom(testArea) then result = true end
    elseif direction == 2 then
      local testArea = createRoom(considerTile.x-1, considerTile.y, 3, corridorLength)
      print(testArea.x .. " " .. testArea.y)
      if validateRoom(testArea) then result = true end
    elseif direction == 3 then
      local testArea = createRoom(considerTile.x-corridorLength, considerTile.y-1, 3, corridorLength)
      print(testArea.x .. " " .. testArea.y)
      if validateRoom(testArea) then result = true end
    elseif direction == 4 then
      local testArea = createRoom(considerTile.x, considerTile.y-1, 3, corridorLength)
      print(testArea.x .. " " .. testArea.y)
      if validateRoom(testArea) then result = true end
    end
  end
  
  return considerTile
end

--function createCorridor(room1, room2)
--  local center1 = roomCenter(room1)
--  local center2 = roomCenter(room2)
--end



-- generate 2 rooms
--[[numRooms = 2
for i = 1, numRooms do
  ::continue::
  local room = createRandomRoom()
  for j = 1, #rooms do
    if (roomOverlaps(rooms[j], room)) then
      print("found overlap")
      goto continue
    end
  end
    
  --overlaps?
  rooms[i] = room
end
]]--

function validateRoom(room)
  if room.y + room.h > level.h then return false
  elseif room.x + room.w > level.w then return false
  elseif room.y < 1 or room.x < 1 then return false
  end
  
  for i = 1, #rooms do
    if roomOverlaps(room, rooms[i]) then
      result = false
      break
    end
  end
  
  return true
end

function cutRooms()
  for i = 1, #rooms do
    local room = rooms[i]
    for y = room.y, room.y + room.h do
      for x = room.x, room.x + room.w do
        local tile
        if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then -- the walls of the room
          tile = "#"
        else
          tile = "."
        end
        
        if x == room.doorTile.x and y == room.doorTile.y then
          tile = "="
        end
        
        level[y][x] = tile
      end
    end
  end
end

function fillLevel()
  for y = 1, level.h do
    level[y] = {}
    for x = 1, level.w do
      tile = "#"
      level[y][x] = tile
    end
    
    level[y][level.w+1] = "\n"
  end
end

function writeLevelToFile() 
  local file = assert(io.open("level.txt", "w"), "Could not open file.")
  file:write("--level" .. "\n")
  for y = 1, level.h do
    for x = 1, level.w+1 do
      file:write(level[y][x])
    end
  end
  file:flush()
  file:close(outputFile)
end

testRoom = createRandomRoom()
while not validateRoom(testRoom) do
  testRoom = createRandomRoom()
end

table.insert(rooms, testRoom)

fillLevel()
--wallTile = selectRandomWallTile(rooms[1])
cutRooms()

writeLevelToFile()

-- print level
for y = 1, level.h do
  for x = 1, level.w+1 do
    io.write(level[y][x])
  end
end

print(rooms[1].x .. " " .. rooms[1].y .. " " .. rooms[1].w .. " " .. rooms[1].h)
--test = {1,2,3,4,5,6}
--print(test)
--print(table.unpack(test,2,5))

