local Door = {
    x = 128,
    y = 128,
    width = 0,
    height = 0,
    traversable = false,
    open = 0,
    gravity = {
        x = 0,
        y = 0
    },
    lock = {
        x = 0,
        y = 0
    }
}

local world_gravity = {
    x = 0,
    y = 0.1,
    ref = 0.1
}

Door._update = function(self)
    if self.gravity.x ~= 0 then
        if math.sign(self.gravity.x) == math.sign(world_gravity.x) then
            self.open = math.min(self.open + math.abs(world_gravity.x), 1)
        else
            self.open = math.max(0, self.open - math.abs(world_gravity.x))
        end
    end

    if self.gravity.y ~= 0 then
        if math.sign(self.gravity.y) == math.sign(world_gravity.y) then
            self.open = math.min(self.open + math.abs(world_gravity.y), 1)
        else
            self.open = math.max(0, self.open - math.abs(world_gravity.y))
        end
    end

    if (self.gravity.x ~= 0) then
        self.lock.x = self.open * 60 * self.gravity.x + self.x
        self.width = self.lock.x - self.x
    else
        self.lock.x = self.x
        self.width = 1
    end

    if (self.gravity.y ~= 0) then
        self.lock.y = self.open * 60 * self.gravity.y + self.y
        self.height = self.lock.y - self.y
    else
        self.height = 1
        self.lock.y = self.y
    end
end

Door._draw = function(self)
    shape.line(self.x, self.y, self.lock.x, self.lock.y, 2)
    shape.circlef(self.x, self.y, 8, 2)
    shape.circlef(self.lock.x, self.lock.y, 4, 3)
end

Door._init = function(self)
    self.lock = {}
end

local Platform = {
    origin_x = 0,
    origin_y = 0,
    target_x = 0,
    target_y = 0,
    x = 0,
    y = 10,
    height = 4,
    width = 64,
    direction_x = 0,
    direction_y = 0,
    mode = 0, -- 0 : cycle ; 1 = ping pong
    progress = 0,
    duration = 0,
    step = 0
}

function sign2(value)
    if value == 0 then
        return 0
    else
        return math.sign(value)
    end
end

Platform._init = function(self)
    self.direction_x = sign2(self.target_x - self.origin_x)
    self.direction_y = sign2(self.target_y - self.origin_y)
    self.step = tiny.dt / self.duration
end

Platform._update = function(self)
    self.progress = self.progress + self.step
    if self.progress > 1.0 then -- reset progress
        self.progress = 0
    end

    local dst = math.dst(self.origin_x, self.origin_y, self.target_x, self.target_y)
    self.x = self.origin_x + self.progress * self.direction_x * dst
    self.y = self.origin_y + self.progress * self.direction_y * dst
end

Platform._draw = function(self)
    shape.rectf(self.x, self.y, self.width, self.height, 1)
end

local Portal = {
    active = true,
    x = 64,
    y = 86,
    r = 12,
    satellites = nil,
    target_level = 0,
    target_x = 0,
    target_y = 0,
    index = 1,
    fragment_width = 0
}

Portal._init = function(self)
    self.satellites = {{
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

    self.target_level = self.customFields.Exit_ref.levelIid

    local current = map.level(self.target_level)

    for e in all(map.entities["PortalExit"]) do
        if e.iid == self.customFields.Exit_ref.entityIid then
            self.target_x = e.x
            self.target_y = e.y
        end
    end

    function square_size(r)
        local diagonal = 2 * r -- Diameter of the circle

        -- Calculate the width (and height) of the square
        local width = math.sqrt(diagonal ^ 2 / 2)

        return width
    end

    local cx = self.target_x + self.width * 0.5
    local cy = self.target_y + self.height * 0.5
    self.fragment_width = square_size(self.r) * 2 + 5

    map.draw(0, 0, -- where to draw?     
    cx - self.fragment_width * 0.5, cy - self.fragment_width * 0.5, -- from where in the max?
    self.fragment_width, self.fragment_width -- size of the fragment
    )

    map.level(current)

    local cx = self.x + self.width * 0.5
    local cy = self.y + self.height * 0.5

    -- draw map next to the other map
    map.draw(self.fragment_width, 0, cx - self.fragment_width * 0.5, cy - self.fragment_width * 0.5,
        self.fragment_width, self.fragment_width)
    gfx.to_sheet(self.index)

end

function check_collision(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and rect1.x + rect1.width > rect2.x and rect1.y < rect2.y + rect2.height and
               rect1.y + rect1.height > rect2.y
end

Portal._update = function(self, player)
    if check_collision(self, player) then
        local current_level = map.level()
        map.level(self.target_level)
        player.x = self.target_x
        player.y = self.target_y
        player.transition = true
        self.on_level_change(map.level(), current_level)
    end
end

Portal._draw = function(self)
    local portal = self
    -- draw portal

    local current = spr.sheet(self.index)

    local cx = self.x + self.width * 0.5
    local cy = self.y + self.height * 0.5

    -- draw current map fragment and create a hole in it
    -- fixme: maybe useless
    spr.sdraw(cx - self.fragment_width * 0.5, cy - self.fragment_width * 0.5, self.fragment_width, 0,
        self.fragment_width, self.fragment_width)

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
    gfx.to_sheet(9) -- temporary sheet

    -- draw the other level fragment
    spr.sdraw(cx - self.fragment_width * 0.5, cy - self.fragment_width * 0.5, 
    0, 0, 
    self.fragment_width, self.fragment_width)

    -- draw the temporary sheet
    spr.sheet(9)
    spr.sdraw()

    spr.sheet(current)
end

local doors = {}
local platforms = {}
local player = {}
local portals = {}

local elements = {}

local factory = {}

factory.createDoor = function(data)
    local d = new(Door, data)
    d:_init()
    table.insert(elements, d)
    table.insert(doors, d)
    return d
end

factory.createPlatform = function(data)
    local p = new(Platform, {
        origin_x = 0,
        origin_y = 0,
        target_x = 0,
        target_y = 128,
        progress = 0.5,
        duration = 3 -- 3 seconds
    })

    p:_init()

    table.insert(platforms, p)
    table.insert(elements, p)

    return p
end

factory.createPortal = function(data, on_level_change)
    local p = new(Portal, data)

    table.insert(portals, p)
    table.insert(elements, p)

    p.index = 10 + #portals

    p:_init()
    p.on_level_change = on_level_change
    return p
end

return factory
