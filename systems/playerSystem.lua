--require("../entities/player")

playerSystem = {}

playerSystem.move = function(player, direction)
  local x, y
  x = player.x + direction.x--+ 0.25 * direction.x
  y = player.y + direction.y--+ 0.25 * direction.y
  return x, y
end

return playerSystem