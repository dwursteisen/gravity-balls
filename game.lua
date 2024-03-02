local Circle = {
    x = 256 * 0.5,
    y = 144 * 0.5,
    r = 0,
    frame = 0,
    paused = true,
    cycle = 1
}

local c = nil
local portal = nil

local Portal = {
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
    }}
}

local player = {
    x = 64,
    y = 64,
}

--
function _init()
    spr.sheet(1)
    spr.sdraw()
    gfx.to_sheet(10) -- backup the sheet

    c = new(Circle)

    portal = new(Portal)
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

        c.x = 256 * 0.5
        c.y = 144 * 0.5

        c.r = juice.circleOut(math.min(c.frame / 15, 1)) * 300 * 0.5
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

    gfx.cls()
    spr.sheet(1)
    spr.sdraw()
    map.draw()
    spr.sheet(3)
    spr.draw(1, player.x, player.y)
    shape.circlef(c.x, c.y, c.r, 0) -- draw transparent circle

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

    gfx.to_sheet(10)

    gfx.cls()
    spr.sheet((c.cycle + 1) % 2)
    spr.sdraw()
    -- draw player
    spr.sheet(3)
    spr.draw(10, player.x, player.y)
    

    -- draw mask
    spr.sheet(10)
    spr.sdraw()

    -- shape.circle(c.x, c.y, c.r, 4)
    -- shape.rectf(256 * 0.5, 144 * 0.5, 16, 16, 4)
end
