
local level = require("level")

local wallTile = "#"
local floorTile = " "

local levelGrid = {}

local up = 1
local down = 2
local left = 3
local right = 4
local maxPathLength = 9

function fillLevel()
  for y = 1, level.h do
    levelGrid[y] = {}
    for x = 1, level.w do
      levelGrid[y][x] = wallTile
    end
    
    levelGrid[y][level.w+1] = "\n"
  end
end

function cutRooms(rooms) -- pass room table
  for i = 1, #rooms do
    local room = rooms[i]
    for y = room.y, room.y + room.h do
      for x = room.x, room.x + room.w do
        local tile
        if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then -- the walls of the room, needs to be done nicer!
          tile = wallTile
        else
          tile = " "
          if rooms == level.mainRooms then
            --tile = "."
            if i == 1 then tile = "." end
            if i == maxPathLength then tile = "," end
          end
        end
        
        if x == room.doorTile.x and y == room.doorTile.y then
          tile = floorTile
          --tile = i
        end
        
        if levelGrid[y] ~= nil and levelGrid[y][x] ~= nil then -- FIX SO THIS NOT NEEDED
          levelGrid[y][x] = tile
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
        tile = floorTile
        --if y == corridor.start.y then tile = "+"        --debug
        --elseif y == corridor.dest.y then tile = "-" end --debug
        
        if levelGrid[y] ~= nil and levelGrid[y][corridor.x] ~= nil then -- FIX SO THIS NOT NEEDED
          levelGrid[y][corridor.x] = tile
        end
      end
    end
    if corridor.direction == left or corridor.direction == right then
      for x = corridor.x, corridor.x + corridor.length do
        tile = floorTile
        --if x == corridor.start.x then tile = "+"        --debug
        --elseif x == corridor.dest.x then tile = "-" end --debug
        
        if levelGrid[corridor.y] ~= nil and levelGrid[corridor.y][x] ~= nil then -- FIX SO THIS NOT NEEDED
          levelGrid[corridor.y][x] = tile
        end
      end
    end    
    
  end
end

function printLevel() 
  for y = 1, level.h do
    for x = 1, level.w+1 do
      io.write(levelGrid[y][x])
    end
  end  
end

fillLevel()
cutRooms(level.mainRooms)
cutCorridors(level.mainCorridors)
cutRooms(level.extraRooms)
cutCorridors(level.extraCorridors)
printLevel()

--printLevel()