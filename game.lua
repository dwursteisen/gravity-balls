local player_factory = require("player")
local entities_factory = require("entities")

local transition = nil

local player = nil
local entities = {}
local gravity_balls = {}
local doors = {}
local camera = nil
local collides = {}

local Circle = {
    x = 128 * 0.5,
    y = 128 * 0.5,
    r = 0,
    frame = 0,
    paused = true,
    cycle = 1
}

local background = {
   Up = {spr = {x = 16, y = 128} },
   Down = { spr = {x = 0, y = 128}}
}

local gravity_colors = {
    Down = 4,
    Up = 3,
    Left = 4,
    Right = 4,
}

Circle._update = function(self)
    self.frame = self.frame + 1

    self.x = 128 * 0.5
    self.y = 128 * 0.5

    self.r = juice.circleOut(math.min(self.frame / 15, 1)) * 200 * 0.5
    if self.r >= 200 * 0.5 then
        player.transition = false
        transition = nil
    end
end

Circle._draw = function(self)
    map.level(self.prev)

    map.draw()

    shape.circlef(self.x, self.y, self.r, 0) -- draw transparent circle
    gfx.to_sheet(8)

    map.level(self.next)
    map.draw()

    spr.sheet(8)
    spr.sdraw()
end

local Camera = {
    x = 0,
    y = 0,
    target_x = 0,
    target_y = 0
}

Camera.move_to = function(self, x, y)

    local cx = math.clamp(0, x - 128 * 0.5, map.width())
    local cy = math.clamp(0, y - 128 * 0.5, map.height())

    self.target_x = cx
    self.target_y = cy
end

Camera._update = function(self)
    self.x = juice.powIn2(self.x, self.target_x, 0.4)
    self.y = juice.powIn2(self.y, self.target_y, 0.4)

    gfx.camera(self.x, self.y)
end


local Particle = {
    x = 0,
    y = 0,
    ttl = 2,
    _draw = nil,
    _update = nil
}
local particles = {
    p = {}
}

particles.create = function(number, factory, update, draw)
    for i = 1, number do
        local p = new(Particle)
        p._update = update
        p._draw = draw
        factory(i, p)
        table.insert(particles.p, p)
    end
end

particles._update = function()
    for k, p in rpairs(particles.p) do
        if p._update ~= nil then
            p._update(p)
        end
        p.ttl = p.ttl - tiny.dt
        if p.ttl < 0 then
            table.remove(particles.p, k)
        end
    end
end

particles._draw = function()
    for p in all(particles.p) do
        if p._draw ~= nil then
            p._draw(p)
        end
    end
end

function on_gravity_change(current_ball)
    for c in all(gravity_balls) do
        c.consumed = false
    end
    current_ball.consumed = true
    player.gravity_str = current_ball.gravity

    local draw = function(p)
        shape.circlef(p.x, p.y, p.r, p.color)
        shape.circle(p.x, p.y, p.r, 1)
    end

    local update = function(p)
        p.x = p.x + p.dir_x
        p.y = p.y + p.dir_y
        p.r = juice.powOut2(1, 3, p.ttl / 0.4)
    end

    local create = function(index, p)
        local angle = (45 * index - 1) * math.pi / 180
        p.r = 3
        p.dir_x = math.cos(angle) * 1
        p.dir_y = math.sin(angle) * 1
        p.x = player.x + player.width * 0.5 + p.dir_x 
        p.y = player.y + player.height * 0.5 + p.dir_y
        p.ttl = 0.3
        p.color = gravity_colors[current_ball.gravity]
        return p
    end

    particles.create(8, create, update, draw)

end

function load_level(new_level, previous_level)
    entities = {}
    gravity_balls = {}
    doors = {}
    collides = {}

    for p in all(map.entities["Portal"]) do
        local portal = entities_factory.createPortal(p, load_level)
        table.insert(entities, portal)
    end

    for p in all(map.entities["Door"]) do
        local portal = entities_factory.createDoor(p)
        table.insert(entities, portal)
        table.insert(collides, portal)
    end

    for c in all(map.entities["Collision"]) do
        table.insert(collides, c)
    end

    for c in all(map.entities["Platform"]) do
        local portal = entities_factory.createPlatform(c)
        table.insert(entities, portal)
        table.insert(collides, portal)
    end

    camera.x = math.clamp(0, player.x - 128 * 0.5, map.width())
    camera.y = math.clamp(0, player.y - 128 * 0.5, map.height())

    gfx.camera(camera.x, camera.y)
    --
    if player.transition then
        transition = new(Circle, {
            prev = previous_level,
            next = new_level
        })
    end

    for p in all(map.entities["GravityBall"]) do
        local portal = entities_factory.createGravityBall(p)
        p.on_gravity_change = on_gravity_change
        table.insert(entities, portal)
        table.insert(gravity_balls, portal)
    end
end

function _init()

    map.level(0)
    for p in all(map.entities["Spawn"]) do
        player = player_factory.createPlayer(p)
    end

    camera = new(Camera)
    load_level()
end

function _update()
    for e in all(entities) do
        e:_update(player)
    end

    player:_update(collides)

    if transition ~= nil then
        transition:_update()
    end

    camera:_update()

    if player.x_dir > 0 then
        camera:move_to(player.x + 10 + player.width * 0.5, player.y + player.height * 0.5)
    elseif player.x_dir < 0 then
        camera:move_to(player.x - 10 + player.width * 0.5, player.y + player.height * 0.5)
    else
        camera:move_to(player.x + player.width * 0.5, player.y + player.height * 0.5)
    end

    particles:_update()
end


function _draw()
    gfx.cls(gravity_colors[player.gravity_str])

    local config = background[player.gravity_str]
    local prec = spr.sheet("tiles.png")
    for i=-16,128 + 16,16 do
        for j=-16, 128 + 16,16 do
            local offset = tiny.frame * 0.2 % 16 * player.gravity_y_sign
            spr.sdraw(camera.x + i +  camera.x % 16, camera.y + offset + j + camera.y % 16, config.spr.x, config.spr.y, 16, 16)
        end
    end
    spr.sheet(prec)

    
    map.layer(1)
    map.draw()
    map.layer(2)
    map.draw()

    for e in all(entities) do
        e:_draw()
    end

    particles:_draw()

    if transition ~= nil then
        transition:_draw()
    end

    player:_draw()
end
