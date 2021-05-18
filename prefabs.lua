prefabs = {}
  prefabs.spawn = function(x, y)
    local spawn = { x = x, y = y, tile = "@" }
    return spawn
  end

  prefabs.boss = function(x, y)
    local boss = { x = x, y = y, tile = "^" }
    return boss
  end
  
  prefabs.door = function(x, y)
    local door = { x = x, y = y, tile = "+" }
    return door
  end
  
  prefabs.key = function(x, y)
    local key = { x = x, y = y, tile = "%" }
    return key
  end
  
  prefabs.chest = function(x, y)
    local chest = { x = x, y = y, tile = "[" }
    return chest
  end

return prefabs