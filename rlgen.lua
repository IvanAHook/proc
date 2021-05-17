local level = {}
level.w = 128
level.h = 64

local up = 1
local down = 2
local left = 3
local right = 4

local maxPathLength = 9
local minRoomSize = 6
local maxRoomSize = 16

local minCorridorLength = 4
local maxCorridorLenght = 8

local extraRoomChance = 0.5

level.mainRooms = {}
level.mainCorridors = {}

level.extraRooms = {}
level.extraCorridors = {}

math.randomseed(os.time())

function createRoom(x, y, w, h)
  local room = {}
  room.x = x
  room.y = y
  room.w = w - 1 -- this cant be right
  room.h = h - 1
  room.doorTile = {}
  
  return room
end

function createRandomRoom()
  x = math.random(1, level.w)
  y = math.random(1, level.h)
  w = math.random(minRoomSize, maxRoomSize)
  h = math.random(minRoomSize, maxRoomSize)
  
  return createRoom(x, y, w, h)
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

function roomCenter(room) 
  local center = {}
  center.x = room.x + room.width / 2
  center.y = room.y + room.height / 2
  return center
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
    
    if #tiles == 0 then -- TODO make this return nil and then we handle it!
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
  for i = 1, #level.mainRooms do
    if roomOverlaps(room, level.mainRooms[i]) then
      print("room overlaped with room: " .. i)
      result = false
      break
    end
  end
  for i = 1, #level.extraRooms do
    if roomOverlaps(room, level.extraRooms[i]) then
      print("room overlaped with extra room: " .. i)
      result = false
      break
    end
  end
  for i = 1, #level.mainCorridors do
    if roomOverlapsCorridor(room, level.mainCorridors[i]) then
      print("room overlaped with corridor: " .. i)
      result = false
      break
    end
  end
  for i = 1, #level.extraCorridors do
    if roomOverlapsCorridor(room, level.extraCorridors[i]) then
      print("room overlaped with extra corridor: " .. i)
      result = false
      break
    end
  end
  
  return result
end

function cutRooms(rooms) -- pass room table
  for i = 1, #rooms do
    local room = rooms[i]
    for y = room.y, room.y + room.h do
      for x = room.x, room.x + room.w do
        local tile
        if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then -- the walls of the room, needs to be done nicer!
          tile = "#"
        else
          tile = " "
          if rooms == level.mainRooms then
            --tile = "."
            if i == 1 then tile = "." end
            if i == maxPathLength then tile = "," end
          end
        end
        
        if x == room.doorTile.x and y == room.doorTile.y then
          tile = "."
          --tile = i
        end
        
        if level[y] ~= nil and level[y][x] ~= nil then -- FIX SO THIS NOT NEEDED
          level[y][x] = tile
        end
      
      end
    end
  end
end

function cutCorridors(corridors) -- pass corridor table
  for i = 1, #corridors do
    local corridor = corridors[i]
    local tile

    if corridor.direction == up or corridor.direction == down then
      for y = corridor.y, corridor.y + corridor.length do
        tile = "."
        if y == corridor.start.y then tile = "+"        --debug
        elseif y == corridor.dest.y then tile = "-" end --debug
        
        if level[y] ~= nil and level[y][corridor.x] ~= nil then -- FIX SO THIS NOT NEEDED
          level[y][corridor.x] = tile
        end
      end
    end
    if corridor.direction == left or corridor.direction == right then
      for x = corridor.x, corridor.x + corridor.length do
        tile = "."
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
      tile = "#"
      level[y][x] = tile
    end
    
    level[y][level.w+1] = "\n"
  end
end

function writeLevelToFile() 
  local file = assert(io.open("level.lua", "w"), "Could not open file.")
  --file:write("--level" .. "\n")
  file:write("local level = {}\n")
  file:write("level.w = " .. level.w .. "\n" ..
              "level.h = " .. level.h .. "\n")
  file:write("mainRooms = {\n")
  for i = 1, #level.mainRooms do
    local room = level.mainRooms[i]
    file:write("{ x = " .. room.x .. ", y = " .. room.y .. ", w = " .. room.w .. ", h = " .. room.h .. " },\n")
  end
  file:write("}\n")
  file:write("extraRooms = {\n")
  for i = 1, #level.extraRooms do
    local room = level.extraRooms[i]
    file:write("{ x = " .. room.x .. ", y = " .. room.y .. ", w = " .. room.w .. ", h = " .. room.h .. ", connectedTo = " .. room.connectedTo .. " },\n")
  end
  file:write("}\n")
  file:write("mainCorridors = {\n")
  for i = 1, #level.mainCorridors do
    local corridor = level.mainCorridors[i]
    --file:write("{ x = " .. room.x .. ", y = " .. room.y .. ", w = " .. room.w .. ", h = " .. room.h .. ", connectedTo = " .. room.connectedTo .. " },\n")
  end
  file:write("}\n")
  --for y = 1, level.h do
  --  for x = 1, level.w+1 do
  --    file:write(level[y][x])
  --  end
  --end
  file:write("return level")
  file:flush()
  file:close(outputFile)
end

function printTable(t, f)

   local function printTableHelper(obj, cnt)

      local cnt = cnt or 0

      if type(obj) == "table" then

         io.write("\n", string.rep("\t", cnt), "{\n")
         cnt = cnt + 1

         for k,v in pairs(obj) do

            if type(k) == "string" then
               io.write(string.rep("\t",cnt), '["'..k..'"]', ' = ')
            end

            if type(k) == "number" then
               io.write(string.rep("\t",cnt), "["..k.."]", " = ")
            end

            printTableHelper(v, cnt)
            io.write(",\n")
         end

         cnt = cnt-1
         io.write(string.rep("\t", cnt), "}")

      elseif type(obj) == "string" then
         io.write(string.format("%q", obj))

      else
         io.write(tostring(obj))
      end 
   end

   if f == nil then
      printTableHelper(t)
   else
      io.output(f)
      io.write("return")
      printTableHelper(t)
      io.output(io.stdout)
   end
 end
 

function run()
  ::start::
  -- create first room
  local firstRoom = createRandomRoom()
  while not validateRoom(firstRoom) do
    firstRoom = createRandomRoom()
  end
  
  table.insert(level.mainRooms, firstRoom)
  
  local nextRoom
  local testCorridor

  while true do
    local currentRoom = level.mainRooms[#level.mainRooms]

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
        table.insert(level.mainCorridors, testCorridor)
        table.insert(level.mainRooms, nextRoom)
        break
      end
    end

    if #level.mainRooms >= maxPathLength then break end -- max rooms reached, add random rooms outside path
    if #roomWallTiles == 0 and #level.mainRooms < maxPathLength then 
      level.mainRooms = {}
      level.mainCorridors = {}
      goto start 
    end -- did not reach max rooms, redo from start
  end
  
  for i = 1, #level.mainRooms-1 do --no extra rooms on final room
    if math.random() < extraRoomChance then
      local roomWallTiles = getRoomWallTiles(level.mainRooms[i])        
      while #roomWallTiles > 0 do
        local corridorLength = math.random(minCorridorLength, maxCorridorLenght)
        level.mainRooms[i].doorTile, roomWallTiles = selectRandomWallTileForCorridor(level.mainRooms[i], roomWallTiles, corridorLength)
        testCorridor = createCorridor(level.mainRooms[i].doorTile.x, level.mainRooms[i].doorTile.y, corridorLength, level.mainRooms[i].doorTile.direction)
        
        print(level.mainRooms[i].doorTile.x .. " AHA")
        
        nextRoom = createNewRoomAtCorridorDest(testCorridor)
        nextRoom.connectedTo = i
        local val = validateRoom(nextRoom)
        if not val then
          print("could not creat extra room for room: " .. i)
        else
          table.insert(level.extraCorridors, testCorridor)
          table.insert(level.extraRooms, nextRoom)
          --break
        end
      end
    end
  end
  
  for i = 1, #level.extraRooms-1 do --no extra rooms on final room
    if math.random() < extraRoomChance then
      local currentRoom = level.extraRooms[i]
      local roomWallTiles = getRoomWallTiles(currentRoom)        
      while #roomWallTiles > 0 do
        local corridorLength = math.random(minCorridorLength, maxCorridorLenght)
        currentRoom.doorTile, roomWallTiles = selectRandomWallTileForCorridor(currentRoom, roomWallTiles, corridorLength)
        testCorridor = createCorridor(currentRoom.doorTile.x, currentRoom.doorTile.y, corridorLength, currentRoom.doorTile.direction)
        
        nextRoom = createNewRoomAtCorridorDest(testCorridor)
        nextRoom.connectedTo = currentRoom.connectedTo
        local val = validateRoom(nextRoom)
        if not val then
          print("could not creat extra room for room: " .. i)
        else
          table.insert(level.extraCorridors, testCorridor)
          table.insert(level.extraRooms, nextRoom)
          --break
        end
      end
    end
  end
    
  --fillLevel()

  cutRooms(level.mainRooms)
  cutCorridors(level.mainCorridors)
  cutRooms(level.extraRooms)
  cutCorridors(level.extraCorridors)


  --writeLevelToFile()
  printTable(level, "level.lua")

  --print level
  --for y = 1, level.h do
  --  for x = 1, level.w+1 do
  --    io.write(level[y][x])
  --  end
  --end

end

run()
