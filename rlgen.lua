level = {}
level.w = 128
level.h = 64
--level.rooms = ""

up = 1
down = 2
left = 3
right = 4

minRoomSize = 6
maxRoomSize = 16

minCorridorLength = 4
maxCorridorLenght = 8

rooms = {}
corridors = {}

math.randomseed(os.time())

function createRoom(x, y, w, h)
  local room = {}
  room.x = x
  room.y = y
  room.w = w - 1 -- this cant be right
  room.h = h - 1
  room.doorTile = {}
  
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
  --room.doorTile = selectRandomWallTile(room)
  return room
end

function createCorridor(x, y, length, direction)
  local corridor = {}
  corridor.start = {}
  corridor.dest = {}
  
  corridor.start.x = x
  corridor.start.y = y
  
  if direction == up then
    y = y - length
    corridor.dest.x = x
    corridor.dest.y = y
  elseif direction == down then 
    corridor.dest.x = x
    corridor.dest.y = y + length
  elseif direction == left then
    x = x - length
    corridor.dest.x = x
    corridor.dest.y = y
  elseif direction == right then
    corridor.dest.x = x + length
    corridor.dest.y = y
  end
  
  corridor.x = x
  corridor.y = y
  corridor.length = length
  corridor.direction = direction
  
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

function getRoomWallTiles(room)
  local tiles = {}
  for y = room.y, room.y + room.h do
    for x = room.x, room.x + room.w do
      
      -- dont want the door to be in any of the rooms corners
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
  return tiles
end

function selectRandomWallTileForCorridor(room, wallTiles, corridorLength)
  local tiles = wallTiles
  local considerTile
  local result = false
  
  while not result do
    --check if there is room in this direction
    --this thing has a bug, but what is it?
    
    tileIndex = math.random(1, #tiles)
    considerTile = table.remove(tiles, tileIndex)
    
    --considerTile = tiles[math.random(1, #tiles)]
    
    local direction -- 1 = up, 2 = down, 3 = left, 4 = right
    if considerTile.y == room.y then direction = up end
    if considerTile.y == room.y + room.h then direction = down end
    if considerTile.x == room.x then direction = left end
    if considerTile.x == room.x + room.w then direction = right end

    considerTile.direction = direction
    
    --create a test room to check for collision where we want to put the corridor, MAKE THIS GENERIC FOR USE WITH ROOMS AS WELL AS CORRIDORS
    local testArea
    if direction == up then
      testArea = createRoom(considerTile.x-1, considerTile.y-corridorLength, 3, corridorLength)
    elseif direction == down then
      testArea = createRoom(considerTile.x-1, considerTile.y, 3, corridorLength)
    elseif direction == left then
      testArea = createRoom(considerTile.x-corridorLength, considerTile.y-1, 3, corridorLength)
    elseif direction == right then
      testArea = createRoom(considerTile.x, considerTile.y-1, 3, corridorLength)
    end
    
    result = true--validateRoom(testArea)
    --if validateRoom(testArea) then result = true end    
    
    if #tiles == 0 then
      print("Found no tile, why?")
      considerTile.x = 1
      considerTile.y = 1
      break 
    end
  end
  
  return considerTile, tiles
end

function createNewRoomAtCorridorDest(corridor)
  local r = {}
  r.w = math.random(minRoomSize, maxRoomSize)
  r.h = math.random(minRoomSize, maxRoomSize)
  r.door = {}
  
  if corridor.direction == up or corridor.direction == down then
    local min = math.ceil(corridor.dest.x - r.w + 2) -- consider walls, this should be fixed, maybe dont consider walls. instead add padding in collision detection
    local max = math.floor(corridor.dest.x - 1)

    r.door.x = math.random(min, max)
    if corridor.direction == up then r.door.y = corridor.dest.y - r.h + 1 -- same wall problem here
    else r.door.y = corridor.dest.y end
  elseif corridor.direction == left or corridor.direction == right then
    local min = math.ceil(corridor.dest.y - r.h + 2)
    local max = math.floor(corridor.dest.y - 1)

    r.door.y = math.random(min, max)
    if corridor.direction == left then r.door.x = corridor.dest.x - r.w + 1 -- same wall problem here
    else r.door.x = corridor.dest.x end
  end
  
  return createRoom(r.door.x, r.door.y, r.w, r.h)
end

function validateRoom(room)
  if room.y + room.h >= level.h then return false
  elseif room.x + room.w >= level.w then return false
  elseif room.y <= 1 or room.x <= 1 then return false
  end
  
  local result = true
  for i = 1, #rooms do
    if roomOverlaps(room, rooms[i]) then
      print("room " .. #rooms + 1 .. " overlaped with room: " .. i)
      result = false
      break
    end
  end
  
  if debug then 
    print("room: " .. #rooms + 1 .. " validate succeded " .. tostring(result))
  else
    print("room: " .. #rooms + 1 .. " validate failed " .. tostring(result))    
  end
  
  return result
end

function cutRooms()
  for i = 1, #rooms do
    local room = rooms[i]
    for y = room.y, room.y + room.h do
      for x = room.x, room.x + room.w do
        local tile
        if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then -- the walls of the room, needs to be done nicer!
          tile = "#"
        else
          tile = "."
          tile = i
        end
        
        if x == room.doorTile.x and y == room.doorTile.y then
          tile = "."
          tile = i
        end
        
        if level[y] ~= nil and level[y][x] ~= nil then -- FIX SO THIS NOT NEEDED
          level[y][x] = tile
        end
      
      end
    end
  end
end

function cutCorridors()
  for i = 1, #corridors do
    local corridor = corridors[i]
    local tile

    if corridor.direction == up or corridor.direction == down then
      for y = corridor.y, corridor.y + corridor.length do
        tile = "*"
        if y == corridor.start.y then tile = "+"        --debug
        elseif y == corridor.dest.y then tile = "-" end --debug
        
        if level[y] ~= nil and level[y][corridor.x] ~= nil then -- FIX SO THIS NOT NEEDED
          level[y][corridor.x] = tile
        end
      end
    end
    if corridor.direction == left or corridor.direction == right then
      for x = corridor.x, corridor.x + corridor.length do
        tile = "*"
        if x == corridor.start.x then tile = "+"        --debug
        elseif x == corridor.dest.x then tile = "-" end --debug
        
        if level[corridor.y] ~= nil and level[corridor.y][x] ~= nil then -- FIX SO THIS NOT NEEDED
          level[corridor.y][x] = tile
        end
      end
    end    
    
  end
end

function fillLevel()
  for y = 1, level.h do
    level[y] = {}
    for x = 1, level.w do
      tile = "."
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

debug = false
function run()
  
  -- create first room
  local firstRoom = createRandomRoom()
  while not validateRoom(firstRoom) do
    firstRoom = createRandomRoom()
  end
  
  table.insert(rooms, firstRoom)
  
  local nextRoom
  local testCorridor

  while true do
    local currentRoom = rooms[#rooms]

    
    local roomWallTiles = getRoomWallTiles(currentRoom)
    
    while #roomWallTiles > 0 do --why this shit code run even tho false!? lua pls explain, i am confusion
      local corridorLength = math.random(minCorridorLength, maxCorridorLenght)
      currentRoom.doorTile, roomWallTiles = selectRandomWallTileForCorridor(currentRoom, roomWallTiles, corridorLength)
      testCorridor = createCorridor(currentRoom.doorTile.x, currentRoom.doorTile.y, corridorLength, currentRoom.doorTile.direction)
      
      nextRoom = createNewRoomAtCorridorDest(testCorridor)
      debug = true
      local val = validateRoom(nextRoom)
      debug = false
      if not val then
        print("validate returned: " .. tostring(val) .. " wall tiles remaning: " .. #roomWallTiles)

      else
        table.insert(corridors, testCorridor)
        table.insert(rooms, nextRoom)
        break
      end
    end

    if #rooms >= 9 then break end -- max rooms reached, add random rooms outside path
    if #roomWallTiles == 0 then break end -- did not reach max rooms, redo from start
  end
  
  fillLevel()

  cutRooms()
  cutCorridors()

  writeLevelToFile()

  --print level
  for y = 1, level.h do
    for x = 1, level.w+1 do
      io.write(level[y][x])
    end
  end

end

run()
