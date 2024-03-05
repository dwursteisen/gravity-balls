local player_factory = require("player")

local Shape = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    type = 0 -- 1 = rectangle ; > 1 = slop 
}

local player = nil

local shapes = nil
local map_shapes = nil
--
function _init()
    for p in all(map.entities["Spawn"]) do
        player = player_factory.createPlayer(p)
    end
    player.world_gravity_y = 0.1
end

function _update()
    player:_update(map.entities["Collision"])

    if ctrl.pressed(keys.r) then
        _init()
    end
end

function _draw()
    gfx.cls()
    map.draw()
    player:_draw()
end
