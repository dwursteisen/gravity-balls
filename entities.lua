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

local doors = nil
local platforms = nil
local player = nil

local elements = nil

function _init()
    player = new(Player, {
        x = 150,
        y = 10
    })

    platforms = {}
    elements = {}
    
    local p = new(Platform, {
        origin_x = 0,
        origin_y = 0,
        target_x = 0,
        target_y = 128,
        progress = 0.5,
        duration = 3 -- 3 seconds
    })
    
    table.insert(platforms, p)
    table.insert(elements, p)
    
    doors = {}

    table.insert(doors, new(Door, {
        id = 1,
        gravity = {
            x = 1,
            y = 0
        }
    }))

    table.insert(doors, new(Door, {
        id = 2,
        gravity = {
            x = -1,
            y = 0
        },
        lock = {}
    }))
    table.insert(doors, new(Door, {
        id = 3,
        gravity = {
            x = 0,
            y = 1
        },
        lock = {}
    }))
    table.insert(doors, new(Door, {
        id = 4,
        gravity = {
            x = 0,
            y = -1
        },
        lock = {}
    }))

    for d in all(doors) do
        table.insert(elements, d)
    end

    for e in all(elements) do
        if e._init then
            e:_init()
        end
    end
end

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

factory.createPortal = function(data)
    
end

return factory