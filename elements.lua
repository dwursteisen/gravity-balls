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

local Player = {
    x = 0,
    y = 0,
    width = 16,
    height = 16,
    traversable = true,
    direction_x = 0,
    direction_y = 0,
    grounded = false,
    jumping = false,
    attached = nil
}

-- Fonction pour vérifier si deux segments s'intersectent
function intersect(v1_start, v1_end, v2_start, v2_end)
    local dir1 = vec2.create(v1_end.x - v1_start.x, v1_end.y - v1_start.y)
    local dir2 = vec2.create(v2_end.x - v2_start.x, v2_end.y - v2_start.y)

    local determinant = vec2.crs(dir1, dir2)

    if determinant == 0 then
        -- parallele segment
        return nil
    end

    local other = vec2.create(v2_start.x - v1_start.x, v2_start.y - v1_start.y)
    local s = vec2.crs(other, dir2) / determinant
    local t = vec2.crs(other, dir1) / determinant

    if s >= 0 and s <= 1 and t >= 0 and t <= 1 then
        -- Les segments s'intersectent
        local intersection_x = v1_start.x + s * dir1.x
        local intersection_y = v1_start.y + s * dir1.y
        return vec2.create(intersection_x, intersection_y)
    else
        -- Les segments ne s'intersectent pas
        return nil
    end
end

Player._update = function(self, platforms)
    local pos = ctrl.touch()
    if ctrl.touching(0) ~= nil then
        self.x = pos.x
        self.y = pos.y
        return
    end

    local energie = {
        x = world_gravity.x * 50,
        y = world_gravity.y * 50
    }

    for p in all(platforms) do
        local player_sensor_start = vec2.create(self.x + self.width * 0.5, self.y)
        local player_sensor_end = vec2.create(self.x + self.width * 0.5, self.y + self.height + energie.y)

        local intersection = intersect(player_sensor_start, player_sensor_end, {
            x = p.x,
            y = p.y + p.height * 0.5 + p.height * 0.5 * sign2(world_gravity.y) * -1
        }, {
            x = p.x + p.width,
            y = p.y + p.height * 0.5 + p.height * 0.5 * sign2(world_gravity.y) * -1
        })

        debug.log("w: "..p.width)
        debug.log("h: "..p.height)
        if intersection ~= nil then
            debug.console("INTESRCET")
            energie = vec2.create(0, 0)
            debug.point(intersection.x, intersection.y)
            self.y = math.floor(intersection.y - (self.height * 0.5 + self.height * 0.5 * sign2(world_gravity.y)))
        end
    end

    self.x = self.x + energie.x
    self.y = self.y + energie.y

    self.x = math.clamp(0, self.x, 256 - self.width)
    self.y = math.clamp(0, self.y, 256 - self.height)
end

Player._draw = function(self)
    shape.rectf(self.x, self.y, self.width, self.height, 3)

    local energie = {
        x = world_gravity.x * 50,
        y = world_gravity.y * 50
    }

    local player_sensor_start = vec2.create(self.x + self.width * 0.5, self.y)
    local player_sensor_end = vec2.create(self.x + self.width * 0.5, self.y + self.height + energie.y)

    shape.line(player_sensor_start.x, player_sensor_start.y, player_sensor_end.x, player_sensor_end.y, 2)
end

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

local updatable = nil
local drawable = nil
local collionable = nil

function _init()
    player = new(Player, {
        x = 150,
        y = 10
    })

    platforms = {}
    updatable = {}
    drawable = {}
    collionable = {}

    

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
        table.insert(drawable, p)
        table.insert(collionable, p)
        table.insert(updatable, p)
        

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
        table.insert(drawable, d)
        table.insert(updatable, d)
        if d.gravity.x ~= 0 then
            table.insert(collionable, d)
        end
    end

end

function _update()

    if (ctrl.pressed(keys.left)) then
        world_gravity.x = world_gravity.ref * -1
        world_gravity.y = 0
    elseif (ctrl.pressed(keys.right)) then
        world_gravity.x = world_gravity.ref * 1
        world_gravity.y = 0

    end

    if (ctrl.pressed(keys.up)) then
        world_gravity.x = 0
        world_gravity.y = world_gravity.ref * -1
    elseif (ctrl.pressed(keys.down)) then
        world_gravity.x = 0
        world_gravity.y = world_gravity.ref * 1
    end

    for u in all(updatable) do
        u:_update()
    end
    player:_update(collionable)
end

function _draw()
    gfx.cls()

    for d in all(drawable) do 
        d:_draw()
    end
    
    player:_draw()
end
