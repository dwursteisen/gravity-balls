local player_factory = require("player")
local entities_factory = require("entities")

local Shape = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    type = 0 -- 1 = rectangle ; > 1 = slop 
}

local player = nil
local entities = {}



function load_level()
    entities = {}
    for p in all(map.entities["Portal"]) do
        local portal = entities_factory.createPortal(p, load_level)
        table.insert(entities, portal)
    end

end

function _init()
    for p in all(map.entities["Spawn"]) do
        player = player_factory.createPlayer(p)
    end

    load_level()    
end

function _update()
    for e in all(entities) do
        e:_update(player)
    end

    player:_update(map.entities["Collision"])

    if ctrl.pressed(keys.r) then
        _init()
    end

end

function _draw()
    gfx.cls()
    map.draw()

    for e in all(entities) do
        e:_draw()
    end

    player:_draw()
end
