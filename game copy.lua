local player_factory = require("player")

local Circle = {
    x = 128 * 0.5,
    y = 128 * 0.5,
    r = 0,
    frame = 0,
    paused = true,
    cycle = 1
}

local c = nil
local portal = nil

local Portal = {
    active = true,
    x = 64,
    y = 86,
    r = 12,
    satellites = {{
        speed = 6,
        dst_x = 8,
        dst_y = 8
    }, {
        speed = 4,
        dst_x = -8,
        dst_y = 8
    }, {
        speed = 5,
        dst_x = -8,
        dst_y = -8
    }},
}

Portal._draw = function(self) 
    local portal = self
    -- draw portal

    shape.circle(portal.x, portal.y, portal.r + math.cos(tiny.t * 5) * 2 + 1, 1)

    for s in all(portal.satellites) do
        shape.circle(portal.x + math.cos(tiny.t * s.speed) * s.dst_x, portal.y + math.sin(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4 + 1, 1)

        shape.circle(portal.x + math.cos(tiny.t * s.speed) * s.dst_x, portal.y + math.cos(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4 + 1, 1)

        shape.circlef(portal.x + math.cos(tiny.t * s.speed) * s.dst_x, portal.y + math.cos(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4, 0)

        shape.circlef(portal.x + math.cos(tiny.t * s.speed) * s.dst_x, portal.y + math.sin(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4, 0)
    end
    shape.circlef(portal.x, portal.y, portal.r + math.cos(tiny.t * 5) * 2, 0)
end

local player = nil

--
function _init()
    spr.sheet(1)
    spr.sdraw()
    gfx.to_sheet(10) -- backup the sheet

    c = new(Circle)

    portal = new(Portal)

    player = player_factory.createPlayer()
end

function restart()
    spr.sheet(c.cycle)
    spr.sdraw()
    gfx.to_sheet(10) -- backup the sheet

    c = new(Circle)
end

function _update()
    if ctrl.pressed(keys.r) then
        restart()
    end

    if ctrl.pressed(keys.space) then
        c.paused = not c.paused
        sfx.play(0)
    end

    if not c.paused then
        c.frame = c.frame + 1

        c.x = 128 * 0.5
        c.y = 128 * 0.5

        c.r = juice.circleOut(math.min(c.frame / 15, 1)) * 200 * 0.5
        if c.r >= 300 * 0.5 then
            -- hack because of the restart
            local cycle = c.cycle
            c.cycle = (cycle + 1) % 2
            restart()
            c.cycle = (cycle + 1) % 2
        end

    end

    if ctrl.pressing(keys.a) then    
        portal.r = portal.r + 1 
    elseif ctrl.pressing(keys.z) then
       portal.r = portal.r - 1 
    end

    if ctrl.pressing(keys.left) then
        player.x = player.x - 1
    elseif ctrl.pressing(keys.right) then
        player.x = player.x + 1
    end

    if ctrl.pressing(keys.up) then
        player.y = player.y - 1
    elseif ctrl.pressing(keys.down) then
        player.y = player.y + 1
    end
end

function _draw()
    -- gfx.pal()

    -- render visible game
    gfx.cls(2)
    map.level(1)
     map.layer(0)
    map.draw()
    
    portal:_draw()
    shape.circlef(c.x, c.y, c.r, 0) -- draw transparent circle

    spr.sheet(3)
    spr.draw(1, player.x, player.y)

    gfx.to_sheet(10)

    -- render background game.
    gfx.cls(2)
    -- spr.sheet((c.cycle + 1) % 2)
    map.level(0)
    map.draw()
    
    -- draw player
    spr.sheet(3)
    spr.draw(10, player.x, player.y)
    

    -- draw mask
    spr.sheet(10)
    spr.sdraw()

    -- shape.circle(c.x, c.y, c.r, 4)
    -- shape.rectf(256 * 0.5, 144 * 0.5, 16, 16, 4)
end
