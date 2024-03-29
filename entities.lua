local Door = {
    x = 128,
    y = 128,
    width = 0,
    height = 0,
    origin_x = 0,
    origin_y = 0,
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
            self.open = math.min(self.open + math.abs(player.gravity_x * 0.1), 1)
        else
            self.open = math.max(0, self.open - math.abs(player.gravity_x * 0.1))
        end
    end

    if self.gravity.y ~= 0 then
        if math.sign(self.gravity.y) == math.sign(player.gravity_y) then
            self.open = math.min(self.open + math.abs(player.gravity_y * 0.1), 1)
        else
            self.open = math.max(0, self.open - math.abs(player.gravity_y * 0.1))
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
        if self.gravity.y < 0 then
            self.y = (1 - self.open) * self.max_height + self.origin_y
            self.lock.y = self.open * self.max_height + self.y
        else
            self.lock.y = self.open * self.max_height * self.gravity.y + self.y
        end
        self.height = self.lock.y - self.y
    else
        self.height = self.max_height
        self.lock.y = self.y
    end
end

Door._draw = function(self)
    local current = spr.sheet("tiles.png")

    spr.sdraw(self.x, self.y, 32, 96, self.width, self.height, true, true)

    spr.sheet(current)
end

Door._init = function(self)
    self.lock = {}
    self.max_height = self.height
    self.max_width = self.width
    self.origin_x = self.x
    self.origin_y = self.y
    if self.customFields.Gravity == "Up" then
        self.gravity = {
            x = 0,
            y = -1
        }
    elseif self.customFields.Gravity == "Left" then
        self.gravity = {
            x = -1,
            y = 0
        }
    elseif self.customFields.Gravity == "Right" then
        self.gravity = {
            x = 1,
            y = 0
        }
    else
        self.gravity = {
            x = 0,
            y = 1
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
    dt_y = 0
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
        self.target_x = self.x + self.width
        self.target_y = self.y
    else
        self.origin_x = self.x
        self.origin_y = self.y
        self.target_x = self.x
        self.target_y = self.y + self.height
    end

    self.width = 16
    self.height = 4

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
    local current = spr.sheet("tiles.png")
    local offset = 0
    spr.sdraw(self.x, self.y, 0, 120 + 4 * offset, self.width, self.height)
    spr.sheet(current)

end

local GravityBall = {
    x = 0,
    y = 10,
    height = 8,
    width = 8,
    r = 4,
    gravity_x = 0,
    gravity_y = 0,
    animation = 0,
    consumed = false,
    gravity = nil,
    on_gravity_change = nil
}

GravityBall._init = function(self)
    if self.customFields.Gravity == "Up" then
        self.gravity_x = 0
        self.gravity_y = -1
        self.animation = 0
    elseif self.customFields.Gravity == "Left" then
        self.gravity_x = -1
        self.gravity_y = 0
    elseif self.customFields.Gravity == "Right" then
        self.gravity_x = 1
        self.gravity_y = 0
    else -- Down
        self.gravity_x = 0
        self.gravity_y = 1
        self.animation = 25
    end

    self.gravity = self.customFields.Gravity
    self.direction = self.customFields.Direction

    if self.direction ~= "null" then
        if self.direction == "Up" then
            self.dy = -1
            self.dx = 0
        elseif self.direction == "Down" then
            self.dy = 1
            self.dx = 0
        elseif self.direction == "Left" then
            self.dx = -1
            self.dy = 0
        else
            self.dx = 1
            self.dy = 0
        end
    else
        self.dx = 0
        self.dy = 0
    end
end

GravityBall._update = function(self, player)
    if self.consumed then
        return
    end

    if math.dst2(self.x, self.y, player.x + player.width * 0.5, player.y + player.height * 0.5) <= 5 * 5 then
        -- colide with player
        player.gravity_x = self.gravity_x * 0.5
        player.gravity_y = self.gravity_y * 0.5
        player.gravity_x_sign = sign2(self.gravity_x)
        player.gravity_y_sign = sign2(self.gravity_y)
        player.y_velociy = 0

        self.consumed = true
        if self.on_gravity_change ~= nil then
            sfx.play(4)
            self.on_gravity_change(self)
        end
    end

    for b in all(self.bouncer) do
        if math.dst2(self.x, self.y, b.x + b.width * 0.5, b.y + b.height * 0.5) <= (self.r * self.r + 4 * 4) then
            self.dx = self.dx * -1
            self.dy = self.dy * -1
        end
    end
    self.x = self.x + self.dx * 0.3
    self.y = self.y + self.dy * 0.3

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

    local previous = spr.sheet("ball.png")
    spr.draw(self.animation + (tiny.frame * 0.2) % 24, self.x - self.r, self.y - self.r)
    spr.sheet(previous)
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

    self.label = self.customFields.label
    self.target_level = self.customFields.Exit_ref.levelIid

    local current = map.level()
    map.level(self.target_level)
    for e in all(map.entities["PortalExit"]) do
        if e.iid == self.customFields.Exit_ref.entityIid then
            self.target_x = e.x
            self.target_y = e.y
        end
    end
    map.level(current)

    function square_size(r)
        local diagonal = 2 * r -- Diameter of the circle

        -- Calculate the width (and height) of the square
        local width = math.sqrt(diagonal ^ 2 / 2)

        return width
    end

    local cx = self.target_x + self.width * 0.5
    local cy = self.target_y + self.height * 0.5
    self.fragment_width = square_size(self.r) * 2 + 5

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
        player.start_x = player.x
        player.start_y = player.y
        player.transition = true
        sfx.play(2)
    
        self.on_level_change(map.level(), current_level)
    end
end

Portal._draw = function(self)

    local portal = self
    -- draw portal

    local cx = self.x + self.width * 0.5
    local cy = self.y + self.height * 0.5

    shape.circle(cx, cy, portal.r + math.cos(tiny.t * 5) * 2 + 1, 1)

    for s in all(portal.satellites) do
        shape.circle(cx + math.cos(tiny.t * s.speed) * s.dst_x, cy + math.sin(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4 + 1, 1)

        shape.circle(cx + math.cos(tiny.t * s.speed) * s.dst_x, cy + math.cos(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4 + 1, 1)

        shape.circlef(cx + math.cos(tiny.t * s.speed) * s.dst_x, cy + math.cos(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4, 2)

        shape.circlef(cx + math.cos(tiny.t * s.speed) * s.dst_x, cy + math.sin(tiny.t * s.speed) * s.dst_y,
            5 + math.sin(tiny.t * s.speed) * 4, 2)
    end
    shape.circlef(cx, cy, portal.r + math.cos(tiny.t * 5) * 2, 2)

    print(self.label, cx - 6, cy, 4)
end

local Death = {
    on_touch = function() end
}

Death._init = function(self)
    self.gravity = self.customFields.Gravity
end

Death._update = function(self, player)
    if check_collision(self, player) then
        self.on_touch(self, player)
    end
end

Death._draw = function(self, player)
    local prec = spr.sheet("tiles.png")

    spr.sdraw(self.x, self.y, 0, 152, 8, 8, false, self.gravity == "Up")

    spr.sheet(prec)
end

local Escargot = {
    dir_x = 1,
    gravity = "Down",
}

Escargot._init = function(self)
    self.gravity = self.customFields.Gravity
end

Escargot._draw = function(self)
    local prec = spr.sheet("escargot.png")
    local i = math.floor(self.x) % 8
    local inv = self.gravity == "Up" 
    local flip = self.dir_x == -1
   
    spr.sdraw(self.x, self.y, i * 16, 0, 16, 8, flip, inv)
    spr.sheet(prec)
end

Escargot._update = function(self, player)
    self.x = self.x + self.dir_x * 0.2

    for b in all(self.bouncer) do
        if check_collision(self, b) then
            self.dir_x = self.dir_x * -1
        end
    end

    if check_collision(self, player) then
        self.on_touch(self, player)
    end
end

local factory = {}

factory.createEscargot = function(data)
    local d = new(Escargot, data)
    d:_init()
    return d
end

factory.createDeath = function(data)
    local d = new(Death, data)
    d:_init()
    return d
end

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
