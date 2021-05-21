require("printTable")
local level = require("level") -- TODO add support for providing level file as input

local emptyTile = " "
local wallTile = "#"
local floorTile = "."

local levelGrid = {}

local up = 1
local down = 2
local left = 3
local right = 4
local maxPathLength = 9

function fillLevel() -- fill levelGrid with wall tiles
  for y = 1, level.params.h do
    levelGrid[y] = {}
    for x = 1, level.params.w do
      levelGrid[y][x] = emptyTile
    end
    
    levelGrid[y][level.params.w+1] = "\n"
  end
end

function cutRooms(rooms) -- cut out rooms in levelGrid
  for i = 1, #rooms do
    local room = rooms[i]
    for y = room.y, room.y + room.h do
      for x = room.x, room.x + room.w do
        local tile
        if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then
          tile = wallTile
        else
          tile = floorTile
        end
        
        for c = 1, #room.contents do
          if room.x + room.contents[c].x == x and room.y + room.contents[c].y == y then
            tile = room.contents[c].tile
          end
        end
        
          levelGrid[y][x] = tile
      end
    end
  end
end

function cutCorridors(corridors) -- cut out corridor in levelGrid
  for i = 1, #corridors do
    local corridor = corridors[i]
    local tile

    if corridor.direction == up or corridor.direction == down then
      for y = corridor.y, corridor.y + corridor.length do
        
        for c = 1, #corridor.contents do
          if corridor.y + corridor.contents[c].y == y then
            tile = corridor.contents[c].tile
          end
        end
        
          levelGrid[y][corridor.x-1] = wallTile
          levelGrid[y][corridor.x] = floorTile
          levelGrid[y][corridor.x+1] = wallTile
      end
    end
    if corridor.direction == left or corridor.direction == right then
      for x = corridor.x, corridor.x + corridor.length do
        
        for c = 1, #corridor.contents do
          if corridor.x + corridor.contents[c].x == x then
            tile = corridor.contents[c].tile
          end
        end
        
          levelGrid[corridor.y-1][x] = wallTile
          levelGrid[corridor.y][x] = floorTile
          levelGrid[corridor.y+1][x] = wallTile
      end
    end    
    
  end
end

function printLevel()
  for y = 1, level.params.h do
    for x = 1, level.params.w+1 do
      io.write(levelGrid[y][x])
    end
  end
  printTable(levelGrid, "levelGrid.lua") 
end

fillLevel()
cutRooms(level.mainRooms)
cutCorridors(level.mainCorridors)
cutRooms(level.extraRooms)
cutCorridors(level.extraCorridors)
printLevel()
