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
    y = 0
}

Camera.move_to = function(self, x, y)
    
    local cx = math.clamp(0, x - 128 * 0.5, map.width())
    local cy = math.clamp(0, y - 128 * 0.5, map.height())


    self.x = juice.pow2(cx, self.x, 0.01)
    self.y = juice.pow2(cy, self.y, 0.01)

    gfx.camera(self.x, self.y)
end

function on_gravity_change(current_ball)
    for c in all(gravity_balls) do
        c.consumed = false
    end
    current_ball.consumed = true
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

    if player.x_dir > 0 then
        camera:move_to(player.x + 10, player.y)
    elseif player.x_dir < 0 then
        camera:move_to(player.x - 10, player.y)
    else
        camera:move_to(player.x, player.y)
    end
end

function _draw()
    gfx.cls()
    map.draw()

    for e in all(entities) do
        e:_draw()
    end

    if transition ~= nil then
        transition:_draw()
    end

    player:_draw()

    for c in all(map.entities["Collision"]) do
        shape.rect(c.x, c.y, c.width, c.height, 8)
    end
end
