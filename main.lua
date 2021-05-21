require("systems/playerSystem")
require("entities/entity")
local gamera = require("lib/gamera")

local cam = gamera.new(0,0,2000,2000)

local tileSize = 8
local width = 128*tileSize
local heigth = 64*tileSize
local success = love.window.setMode(width, heigth, flags)

local levelGrid

local gameEntities = {}
gameEntities.players = {}
gameEntities.entities = {}

function drawCorridors(corridors)
  for i = 1, #corridors do
    local corridor = corridors[i]

    if corridor.direction == 1 or corridor.direction == 2 then
      for y = corridor.y, corridor.y + corridor.length do
        
        for c = 1, #corridor.contents do
          if corridor.y + corridor.contents[c].y == y then
            --tile = corridor.contents[c].tile
          end
        end
        
        love.graphics.draw(wall, (corridor.x-1)*tileSize, y*tileSize)
        love.graphics.draw(floor, corridor.x*tileSize, y*tileSize)
        love.graphics.draw(wall, (corridor.x+1)*tileSize, y*tileSize)
      end
    end
    if corridor.direction == 3 or corridor.direction == 4 then
      for x = corridor.x, corridor.x + corridor.length do
        
        for c = 1, #corridor.contents do
          if corridor.x + corridor.contents[c].x == x then
            --tile = corridor.contents[c].tile
          end
        end
        
        love.graphics.draw(wall, x*tileSize, (corridor.y-1)*tileSize)
        love.graphics.draw(floor, x*tileSize, corridor.y*tileSize)
        love.graphics.draw(wall, x*tileSize, (corridor.y+1)*tileSize)
      end
    end
  end
end

function drawWalls(rooms)
  for i = 1, #rooms do
    local room = rooms[i]
    for y = room.y, room.y + room.h do
      for x = room.x, room.x + room.w do
        if y == room.y or y == room.y + room.h or x == room.x or x == room.x + room.w then
            love.graphics.draw(wall, x*tileSize, y*tileSize)
        else
            love.graphics.draw(floor, x*tileSize, y*tileSize)
        end
      end
    end
  end
end

function drawLevel(grid)
    local screenPos = {}
    screenPos.x, screenPos.y = cam:getPosition()
    
    local topLeft = {}
    topLeft.x = screenPos.x - width/4
    topLeft.y = screenPos.y - heigth/4
    
    for y = 1, #grid do
      for x = 1, #grid[y] do
        if grid[y][x] == "#" then
          love.graphics.draw(wall, x*tileSize, y*tileSize)
          love.graphics.rectangle("fill", topLeft.x+x, topLeft.y+y, 1, 1)
        end
        if grid[y][x] == "." then
          love.graphics.draw(floor, x*tileSize, y*tileSize)
          love.graphics.rectangle("fill", topLeft.x+x, topLeft.y+y, 1, 1)
        end
      end
    end
end

function love.load()
  print("start. <<<")
  love.graphics.setDefaultFilter( 'nearest', 'nearest' )
  cam:setWindow(0, 0, width, heigth)
  cam:setScale(2.0)

  level = require("level")
  levelGrid = require("levelGrid")
  wall = love.graphics.newImage("graphics/test_tile.png")
  tile2 = love.graphics.newImage("graphics/test_tile2.png")
  floor = love.graphics.newImage("graphics/test_floor.png")
  
  local player = entity
  player.graphic = love.graphics.newImage("graphics/player.png")
  player.x = level.mainRooms[1].x + level.mainRooms[1].contents[1].x
  player.y = level.mainRooms[1].y + level.mainRooms[1].contents[1].y
  table.insert(gameEntities.players, player)
end

function love.update(dt)
--[[  if love.keyboard.isDown("up") then
  end
  if love.keyboard.isDown("down") then
  end
  if love.keyboard.isDown("left") then
  end
  if love.keyboard.isDown("right") then
  end ]]--
end

function love.mousepressed(x, y, button, istouch)
   if button == 1 then
   end
end

function love.keypressed(key)
  local nextPos = {}
  nextPos.x = 0
  nextPos.y = 0
  if key == 'up' then
    nextPos.x, nextPos.y = playerSystem.move(gameEntities.players[1], { x = 0, y = -1})
  elseif key == 'down' then
    nextPos.x, nextPos.y = playerSystem.move(gameEntities.players[1], { x = 0, y = 1})
  elseif key == 'left' then
    nextPos.x, nextPos.y = playerSystem.move(gameEntities.players[1], { x = -1, y = 0})
  elseif key == 'right' then
    nextPos.x, nextPos.y = playerSystem.move(gameEntities.players[1], { x = 1, y = 0})
  else
    return
  end
  
  
  if levelGrid[nextPos.y][nextPos.x] ~= "#" then
    gameEntities.players[1].x = nextPos.x
    gameEntities.players[1].y = nextPos.y
  end
  
--  print("colliding with:" .. [nextPos.y][nextPos.x])
  
  cam:setPosition(gameEntities.players[1].x*tileSize, gameEntities.players[1].y*tileSize)
end



function love.draw()
  cam:draw(function(l,t,w,h)
    --draw world
    drawLevel(levelGrid)
    --[[drawWalls(level.mainRooms)
    drawWalls(level.extraRooms)
    drawCorridors(level.mainCorridors)
    drawCorridors(level.extraCorridors)
    ]]--
    
    --draw entities
    local player = gameEntities.players[1]
    love.graphics.draw(player.graphic, player.x*tileSize, player.y*tileSize)
  end)
end

function love.focus(f)
  --gameIsPaused = not f
end

function love.quit()
  print(">>> end.")
end

