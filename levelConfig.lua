require("prefabs")

levelConfig = {}
levelConfig.params = {}
levelConfig.params.w = 128
levelConfig.params.h = 64

levelConfig.params.maxPathLength = 9

levelConfig.params.minRoomSize = 6
levelConfig.params.maxRoomSize = 16

levelConfig.params.minCorridorLength = 4
levelConfig.params.maxCorridorLenght = 8

levelConfig.params.extraRoomChance = 0.5

levelConfig.postProcess = function(levelContents) -- after rooms and corridors are generated, add prefabs to them
  
  local spawn = prefabs.spawn(math.floor(levelContents.mainRooms[1].w /2), math.floor(levelContents.mainRooms[1].h /2)) -- add spawn point
  table.insert(levelContents.mainRooms[1].contents, spawn)
  
  --[[
  for i = 1, #levelContents.mainRooms do
    local rand = math.random()
    if rand > 0.75 then  -- every room on main path has 75% chance to spawn boss
      local room = levelContents.mainRooms[i]
      local boss = prefabs.boss(math.random(1, room.w-1), math.random(1, room.h-1))
      table.insert(room.contents, boss)
    end
  end
  
  local numKeys = 0
  for i = 1, #levelContents.extraRooms do
    local room = levelContents.extraRooms[i]
    if room.connectedTo <= 3 then -- add keys to rooms before third room on main path
      local key = prefabs.key(math.random(1, room.w-1), math.random(1, room.h-1))
      table.insert(room.contents, key)
      numKeys = numKeys + 1
    end
  end
  
  local numDoors = 0
  for i = 1, #levelContents.mainCorridors do
    if i > 3 and numDoors < numKeys then -- add doors to rooms after third room on main path and no more than the number of keys
      local corridor = levelContents.mainCorridors[i]
      local door = prefabs.door(math.random(1, corridor.length-1), math.random(1, corridor.length-1))
      table.insert(levelContents.mainCorridors[i].contents, door)
      numDoors = numDoors + 1
    end
  end
  ]]--
  
end

return levelConfig