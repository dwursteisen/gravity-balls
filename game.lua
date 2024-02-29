local Circle = {
    x = 256 * 0.5,
    y = 144 * 0.5,
    r = 0,
    frame = 0,
    paused = true,
    cycle = 1
}

local c = nil

function _init()
    spr.sheet(1)
    spr.sdraw()
    gfx.to_sheet(2) -- backup the sheet

    c = new(Circle)
end

function restart()
    spr.sheet(c.cycle)
    spr.sdraw()
    gfx.to_sheet(2) -- backup the sheet

    c = new(Circle)
end

function _update()
    if ctrl.pressed(keys.r) then
       restart()
    end

    if ctrl.pressed(keys.space) then
        c.paused = not c.paused
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
end

function _draw()
    spr.sheet(2)
    spr.sdraw()
    shape.circlef(c.x, c.y, c.r, 0) -- draw transparent circle
    gfx.to_sheet(2)

    gfx.cls()
    spr.sheet((c.cycle + 1) % 2)
    spr.sdraw()

    -- draw mask
    spr.sheet(2)
    spr.sdraw()

    -- shape.circle(c.x, c.y, c.r, 4)
    -- shape.rectf(256 * 0.5, 144 * 0.5, 16, 16, 4)
end
