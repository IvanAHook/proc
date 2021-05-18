require("printTable")
require("prefabs")

local up = 1
local down = 2
local left = 3
local right = 4


level = {}
level.params = {}

-- params used if no levelConfig file is provided
level.params.w = 128
level.params.h = 64

level.params.maxPathLength = 9
level.params.minRoomSize = 8
level.params.maxRoomSize = 16

level.params.minCorridorLength = 4
level.params.maxCorridorLenght = 8

level.params.extraRoomChance = 0.5

level.mainRooms = {}
level.mainCorridors = {}

level.extraRooms = {}
level.extraCorridors = {}

math.randomseed(os.time())

function createRoom(x, y, w, h)
  local room = {}
  room.x = x
  room.y = y
  room.w = w - 1
  room.h = h - 1
  room.doorTile = {}
  
  room.contents = {}
  
  return room
end

function createRandomRoom()
  x = math.random(1, level.params.w)
  y = math.random(1, level.params.h)
  w = math.random(level.params.minRoomSize, level.params.maxRoomSize)
  h = math.random(level.params.minRoomSize, level.params.maxRoomSize)
  
  return createRoom(x, y, w, h)
end

function createCorridor(x, y, length, direction) -- TODO make some generic function to determine corridor direction etc, dont want to require x, start.x, dest.x etc
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
  corridor.contents = {}
  
  return corridor
end

function roomOverlaps(room1, room2)
  return room1.x <= room2.x+room2.w and room1.x+room1.w >= room2.x and room1.y <= room2.y+room2.h and room1.y+room1.h >= room2.y
end

function roomOverlapsCorridor(room, corridor)
  if corridor.direction == up or corridor.direction == y then
    return room.x <= corridor.x+1 and room.x+room.w >= corridor.x-1 and room.y <= corridor.y+corridor.length and room.y+room.h > corridor.y
  else
    return room.x <= corridor.x+corridor.length and room.x+room.w >= corridor.x and room.y <= corridor.y+1 and room.y+room.h >= corridor.y-1
  end
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

  tileIndex = math.random(1, #tiles)
  considerTile = table.remove(tiles, tileIndex)
  
  local direction
  if considerTile.y == room.y then direction = up end
  if considerTile.y == room.y + room.h then direction = down end
  if considerTile.x == room.x then direction = left end
  if considerTile.x == room.x + room.w then direction = right end

  considerTile.direction = direction

  if #tiles == 0 then
    return nil
  end
  
  return considerTile, tiles
end

function createNewRoomAtCorridorDest(corridor)
  local room = {}
  room.w = math.random(level.params.minRoomSize, level.params.maxRoomSize)
  room.h = math.random(level.params.minRoomSize, level.params.maxRoomSize)
  room.door = {}
  
  if corridor.direction == up or corridor.direction == down then
    local min = math.ceil(corridor.dest.x - room.w + 2) -- +2 to consider walls
    local max = math.floor(corridor.dest.x - 1) -- -1 because destination will be in room wall

    room.door.x = math.random(min, max)
    if corridor.direction == up then room.door.y = corridor.dest.y - room.h + 1
    else room.door.y = corridor.dest.y end
  elseif corridor.direction == left or corridor.direction == right then
    local min = math.ceil(corridor.dest.y - room.h + 2)
    local max = math.floor(corridor.dest.y - 1)

    room.door.y = math.random(min, max)
    if corridor.direction == left then room.door.x = corridor.dest.x - room.w + 1
    else room.door.x = corridor.dest.x end
  end
  
  return createRoom(room.door.x, room.door.y, room.w, room.h)
end

function validateRoom(room)
  -- is room outside level?
  if room.y + room.h >= level.params.h then return false
  elseif room.x + room.w >= level.params.w then return false
  elseif room.y <= 1 or room.x <= 1 then return false
  end
  
  -- does room overlap with another room or corridor?
  local result = true
  for i = 1, #level.mainRooms do
    if roomOverlaps(room, level.mainRooms[i]) then result = false break end
  end
  for i = 1, #level.extraRooms do
    if roomOverlaps(room, level.extraRooms[i]) then result = false break end
  end
  for i = 1, #level.mainCorridors do
    if roomOverlapsCorridor(room, level.mainCorridors[i]) then result = false break end
  end
  for i = 1, #level.extraCorridors do
    if roomOverlapsCorridor(room, level.extraCorridors[i]) then result = false break end
  end
  
  return result
end

function run(conf)
  if conf ~= nil then
    require(conf)
    level.params = levelConfig.params
  end
  
  local tries = 100
  ::start::
  
  -- create first room
  local firstRoom = createRandomRoom()
  while not validateRoom(firstRoom) do
    firstRoom = createRandomRoom()
  end
  table.insert(level.mainRooms, firstRoom)
  
  local nextRoom
  local testCorridor

  if tries == 0 then
    print("could not create level from provided parameters!")
    return
  end

  while tries > 0 do -- add the main path of the level
    local currentRoom = level.mainRooms[#level.mainRooms]
    local roomWallTiles = getRoomWallTiles(currentRoom)
    
    while #roomWallTiles > 0 do -- generate next room
      local corridorLength = math.random(level.params.minCorridorLength, level.params.maxCorridorLenght)
      currentRoom.doorTile, roomWallTiles = selectRandomWallTileForCorridor(currentRoom, roomWallTiles, corridorLength)
      
      if currentRoom.doorTile == nil then
        break
      end
      
      testCorridor = createCorridor(currentRoom.doorTile.x, currentRoom.doorTile.y, corridorLength, currentRoom.doorTile.direction)
      nextRoom = createNewRoomAtCorridorDest(testCorridor)
      local val = validateRoom(nextRoom)
      if val then
        table.insert(level.mainCorridors, testCorridor)
        table.insert(level.mainRooms, nextRoom)
        break
      end
    end

    if #level.mainRooms >= level.params.maxPathLength then break end -- max rooms reached, add random rooms outside path
    if roomWallTiles == nil or (#roomWallTiles == 0 and #level.mainRooms < level.params.maxPathLength) then 
      level.mainRooms = {}
      level.mainCorridors = {}
      tries = tries - 1
      goto start 
    end -- did not reach max rooms, redo from start
  end
  
  for i = 1, #level.mainRooms-1 do --add extra rooms outside the main path, no extra rooms on final room for now
    if math.random() < level.params.extraRoomChance then
      local roomWallTiles = getRoomWallTiles(level.mainRooms[i])        
      while #roomWallTiles > 0 do
        local corridorLength = math.random(level.params.minCorridorLength, level.params.maxCorridorLenght)
        level.mainRooms[i].doorTile, roomWallTiles = selectRandomWallTileForCorridor(level.mainRooms[i], roomWallTiles, corridorLength)
        
        if level.mainRooms[i].doorTile == nil then
          break
        end
        
        testCorridor = createCorridor(level.mainRooms[i].doorTile.x, level.mainRooms[i].doorTile.y, corridorLength, level.mainRooms[i].doorTile.direction)
        
        nextRoom = createNewRoomAtCorridorDest(testCorridor)
        nextRoom.connectedTo = i
        local val = validateRoom(nextRoom)
        if val then
          table.insert(level.extraCorridors, testCorridor)
          table.insert(level.extraRooms, nextRoom)
        end
      end
    end
  end
  
  if levelConfig.postProcess ~= nil then levelConfig.postProcess(level) end
  
  printTable(level, "level.lua") -- TODO when support is added for printing levels from file input, let the user choose output file
end

run(arg[1])

