local Door = {
    x = 128,
    y = 128,
    width = 0,
    height = 0,
    max_width = 0,
    max_height = 0,
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

Door._update = function(self, player)
    if self.gravity.x ~= 0 then
        if math.sign(self.gravity.x) == math.sign(player.gravity_x) then
            self.open = math.min(self.open + math.abs(player.gravity_x), 1)
        else
            self.open = math.max(0, self.open - math.abs(player.gravity_x))
        end
    end

    if self.gravity.y ~= 0 then
        if math.sign(self.gravity.y) == math.sign(player.gravity_y) then
            self.open = math.min(self.open + math.abs(player.gravity_y), 1)
        else
            self.open = math.max(0, self.open - math.abs(player.gravity_y))
        end
    end

    if (self.gravity.x ~= 0) then
        self.lock.x = self.open * self.max_width * self.gravity.x + self.x
        self.width = self.lock.x - self.x
    else
        self.lock.x = self.x
        self.width = self.max_width
    end

    if (self.gravity.y ~= 0) then
        self.lock.y = self.open * self.max_height * self.gravity.y + self.y
        self.height = self.lock.y - self.y
    else
        self.height = self.max_height
        self.lock.y = self.y
    end
end

Door._draw = function(self)
    shape.line(self.x, self.y, self.lock.x, self.lock.y, 2)
    shape.circlef(self.x, self.y, 8, 2)
    shape.circlef(self.lock.x, self.lock.y, 4, 3)

    shape.rect(self.x, self.y, self.width, self.height, 3)
end

Door._init = function(self)
    self.lock = {}
    self.max_height = self.height
    self.max_width = self.width

    if self.customFields.Gravity == "Up" then 
        self.gravity = {
            x = 0, y = -1
        }
    elseif self.customFields.Gravity == "Left" then 
        self.gravity = {
            x = -1, y = 0
        }
    elseif self.customFields.Gravity == "Right" then 
        self.gravity = {
            x = 1, y = 0
        }
    else
        self.gravity = {
            x = 0, y = 1
        }
    end

end

local Platform = {
    origin_x = 0,
    origin_y = 0,
    target_x = 0,
    target_y = 0,
    x = 0,
    y = 10,
    traversable = true,
    moveable = true, -- the player should tick to these object
    height = 4,
    width = 64,
    direction_x = 0,
    direction_y = 0,
    mode = 0, -- 0 : cycle ; 1 = ping pong
    progress = 0,
    duration = 0,
    step = 0,
    dt_x = 0,
    dt_y = 0,
}

function sign2(value)
    if value == 0 then
        return 0
    else
        return math.sign(value)
    end
end

Platform._init = function(self)
   
    if self.customFields.Gravity == "Up" then
        self.origin_x = self.x
        self.origin_y = self.y + self.height
        self.target_x = self.x
        self.target_y = self.y

    elseif self.customFields.Gravity == "Left" then
        self.origin_x = self.x + self.width
        self.origin_y = self.y
        self.target_x = self.x
        self.target_y = self.y

    elseif self.customFields.Gravity == "Right" then
        self.origin_x = self.x 
        self.origin_y = self.y
        self.target_x = self.x+ self.width
        self.target_y = self.y
    else
        self.origin_x = self.x
        self.origin_y = self.y
        self.target_x = self.x
        self.target_y = self.y +  self.height
    end

    self.height = 4
    self.width = 32

    -- self.duration = 3
    
    self.direction_x = sign2(self.target_x - self.origin_x)
    self.direction_y = sign2(self.target_y - self.origin_y)
    self.step = 0.01
    self.dst = math.floor(math.dst(self.origin_x, self.origin_y, self.target_x, self.target_y))


end

Platform._update = function(self, player)
    self.progress = self.progress + self.step
    if self.progress > 1.0 then -- reset progress
        self.progress = 0
        player.stick_to = nil
    end

    local cx = self.x
    local cy = self.y
    self.x = math.floor(self.origin_x + self.progress * self.direction_x * self.dst)
    self.y = math.floor(self.origin_y + self.progress * self.direction_y * self.dst)

    self.dt_x = cx - self.x
    self.dt_y = cy - self.y
end

Platform._draw = function(self)
    shape.rectf(self.x, self.y, self.width, self.height, 1)
end

local GravityBall = {
    x = 0,
    y = 10,
    height = 8,
    width = 8,
    r = 4,
    gravity_x = 0,
    gravity_y = 0,
    consumed = false,
    gravity = nil,
    on_gravity_change = nil
}

GravityBall._init = function(self)
    if self.customFields.Gravity == "Up" then
        self.gravity_x = 0
        self.gravity_y = -1
    elseif self.customFields.Gravity == "Left" then
        self.gravity_x = -1
        self.gravity_y = 0
    elseif self.customFields.Gravity == "Right" then
        self.gravity_x = 1
        self.gravity_y = 0
    else -- Down
        self.gravity_x = 0
        self.gravity_y = 1
    end

    self.gravity = self.customFields.Gravity
end

GravityBall._update = function(self, player)
    if self.consumed then
        return
    end

    if math.dst2(self.x, self.y, player.x + player.width * 0.5, player.y + player.height * 0.5) <= 4 * 4 then
        -- colide with player
        player.gravity_x = self.gravity_x * 0.5
        player.gravity_y = self.gravity_y * 0.5
        player.gravity_x_sign = sign2(self.gravity_x)
        player.gravity_y_sign = sign2(self.gravity_y)
        player.y_velociy = 0

        self.consumed = true
        if self.on_gravity_change ~= nil then
            self.on_gravity_change(self)
        end
    end
end

GravityBall._draw = function(self)
    if self.consumed then
        return
    end

    local color = 0
    if self.gravity == "Up" then
        color = 3
    elseif self.gravity == "Left" then
        color = 4
    elseif self.gravity == "Right" then
        color = 5
    else
        color = 6
    end

    shape.circlef(self.x, self.y, self.r, color)
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
    spr.sdraw(cx - self.fragment_width * 0.5, cy - self.fragment_width * 0.5, 0, 0, self.fragment_width,
        self.fragment_width)

    -- draw the temporary sheet
    spr.sheet(9)
    spr.sdraw()

    spr.sheet(current)
end

local factory = {}

factory.createDoor = function(data)
    local d = new(Door, data)
    d:_init()
    return d
end

factory.createPlatform = function(data)
    local p = new(Platform, data)

    p:_init()

    return p
end

local portals_id = 0

factory.createPortal = function(data, on_level_change)
    local p = new(Portal, data)

    p.index = 10 + portals_id
    portals_id = portals_id + 1

    p:_init()
    p.on_level_change = on_level_change
    return p
end

factory.createGravityBall = function(data, on_gravity_change)
    local p = new(GravityBall, data)
    
    p:_init()
    p.on_gravity_change = on_gravity_change
    return p
end

return factory
