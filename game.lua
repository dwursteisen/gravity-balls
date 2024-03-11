local player_factory = require("player")
local entities_factory = require("entities")
local sequencer = require("sequencer")

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
    cycle = 1,
    ttl = 1
}

local background = {
    Up = {
        spr = {
            x = 16,
            y = 128
        }
    },
    Down = {
        spr = {
            x = 0,
            y = 128
        }
    }
}

local gravity_colors = {
    Down = 4,
    Up = 3,
    Left = 4,
    Right = 4
}

local rgravity_colors = {
    Down = 3,
    Up = 4,
    Left = 3,
    Right = 3
}

function restart_level()
    for g in all(gravity_balls) do
        g.consumed = false
    end
    player:restart()
    load_level(map.level(), map.level())
    return true
end

function triangle(x, y, size, color, rnd)
    local cx = x
    local cy = y
    local a = math.perlin(tiny.frame / rnd, tiny.frame / rnd * 2, tiny.frame / rnd + 50) * 2 * math.pi
    local b = size + math.perlin(tiny.frame / 50, tiny.frame / 100, tiny.frame / 200) * 20
    shape.trianglef( -- triangle
    2 + cx + math.cos(a) * b, 2 + cy + math.sin(a) * b, -- a
    2 + cx + math.cos(a + math.pi * 2 / 3) * b, 2 + cy + math.sin(a + math.pi * 2 / 3) * b, -- b
    2 + cx + math.cos(a + math.pi * 4 / 3) * b, 2 + cy + math.sin(a + math.pi * 4 / 3) * b, -- c
    1)

    shape.trianglef( -- triangle
    cx + math.cos(a) * b, cy + math.sin(a) * b, -- a
    cx + math.cos(a + math.pi * 2 / 3) * b, cy + math.sin(a + math.pi * 2 / 3) * b, -- b
    cx + math.cos(a + math.pi * 4 / 3) * b, cy + math.sin(a + math.pi * 4 / 3) * b, -- c
    color)

end

function draw_background()
    local config = background[player.gravity_str]
    local prec = spr.sheet("tiles.png")
    for i = -16, 128 + 16, 16 do
        for j = -16, 128 + 16, 16 do
            local offset = tiny.frame * 0.2 % 16 * player.gravity_y_sign
            spr.sdraw(camera.x + i + camera.x % 16, camera.y + offset + j + camera.y % 16, config.spr.x, config.spr.y,
                16, 16)
        end
    end
    spr.sheet(prec)

    local cx = camera.x + 128 * 0.4
    local cy = camera.y + 128 * 0.5

    local p1 = math.perlin(tiny.frame / 100, tiny.frame / 100, tiny.frame / 100) * 30
    local p2 = math.perlin(tiny.frame / 200, tiny.frame / 200, tiny.frame / 200) * 30
    local p3 = math.perlin(tiny.frame / 300, tiny.frame / 300, tiny.frame / 300) * 30
    triangle(camera.x + 128 * 0.1 + p1, camera.y + 128 * 0.1 + p2, 5, rgravity_colors[player.gravity_str], 150)
    triangle(camera.x + 128 * 0.8 + p2, camera.y + 128 * 0.1 + p3, 5, rgravity_colors[player.gravity_str], 250)
    triangle(camera.x + 128 * 0.5 + p3, camera.y + 128 * 0.7 + p1, 5, rgravity_colors[player.gravity_str], 200)
    triangle(cx + p2, cy + p1, 20, 2, 100)

    map.layer(1)
    map.draw()
    map.layer(2)
    map.draw()
end

Circle._update = function(self)
    self.frame = self.frame + 1

    if self.ttl < 0.5 then
        self.r = juice.circleIn(0, 200, self.ttl / 0.5)
    else
        self.r = juice.circleIn(200, 10, (self.ttl - 0.5) / 0.5)
    end

    self.ttl = self.ttl - tiny.dt
    if self.ttl < 0 then
        map.level(self.next)
        player.transition = false
        transition = nil
    end
end

Circle._draw = function(self)
    for i = 0, 5 do
        local r = math.max(0, self.r - i * 20)
        shape.circlef(self.x, self.y, r, 3 + (i % 2))
    end
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
    self.x = math.clamp(0, juice.powIn2(self.x, self.target_x, 0.4), map.width() - 128)
    self.y = math.clamp(0, juice.powIn2(self.y, self.target_y, 0.4), map.height() - 128)

    gfx.camera(math.floor(self.x), math.floor(self.y))
end

local Title = {}

Title._update = function(self)
end

Title._draw = function(self)
    local prev = spr.sheet("tiles.png")
    for column = 0, 97 - 1, 1 do
        local offset = juice.linear(math.cos((tiny.frame + column * 4) / 5)) * 0.8

        spr.sdraw(self.x + column, self.y + offset, -- position on the screen
        120 + column, 72, -- position in the spritesheet
        1, 41 -- size
        )

    end
    spr.sheet(prev)
end

local Progress = {
    x = (128 - 80) * 0.5,
    y = 0,
    width = 80,
    height = 10,
    progress = 0,
    max = 9
}

local progress = nil

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

function add_dust(x, y, gravity)

    local factory = function(index, p)
        p.x = x + 4 + math.rnd(4)
        if gravity == "Up" then
            p.y = y - 2 + math.rnd(5)
        else
            p.y = y + 6 + math.rnd(5)
        end
        p.ttl = 0.4
        p.r = 4
        return p
    end

    local update = function(p)
        p.r = juice.powOut2(0, p.r, p.ttl / 0.3)
    end

    local draw = function(p)
        shape.circlef(p.x, p.y, p.r, 2)
        shape.circle(p.x, p.y, p.r, 1)
    end
    particles.create(3, factory, update, draw)
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

local win_circle1 = function(t, t_action, frame)
    if frame == 0 then
        local create = function(index, p)
            p.x = player.x + player.width * 0.5
            p.y = player.y + player.height * 0.5
            p.r = 80
            p.ttl = 1.1
            return p
        end

        local update = function(p)
            p.r = juice.powOut2(10, 80, (math.max(0, p.ttl - 0.5)) / 0.5)
        end

        local draw = function(p)
            gfx.to_sheet(10)
            gfx.cls(2)
            shape.circlef(p.x, p.y, p.r, 0)
            shape.circle(p.x, p.y, p.r, 1)
            gfx.to_sheet(9)
            local before = spr.sheet(10)
            spr.sdraw(camera.x, camera.y)
            spr.sheet(9)
            spr.sdraw(camera.x, camera.y)
            spr.sheet(before)
        end

        particles.create(1, create, update, draw)
    end
    return t_action >= 0.5
end

local start_win_animation = function(t, t_action, frame)
    sfx.play(3)
    return true
end

local win_animation = function(t, t_action)
    return t_action >= 0.5
end

local win_circle2 = function(t, t_action, frame)
    if frame == 0 then
        local create = function(index, p)
            p.x = player.x + player.width * 0.5
            p.y = player.y + player.height * 0.5
            p.r = 10
            p.ttl = 0.6
            return p
        end

        local update = function(p)
            p.r = juice.powOut2(1, 10, p.ttl / 0.5)
        end

        local draw = function(p)
            gfx.to_sheet(10)
            gfx.cls(2)
            shape.circlef(p.x, p.y, p.r, 0)
            shape.circle(p.x, p.y, p.r, 1)
            gfx.to_sheet(9)
            local before = spr.sheet(10)
            spr.sdraw(camera.x, camera.y)
            spr.sheet(9)
            spr.sdraw(camera.x, camera.y)
            spr.sheet(before)
        end

        particles.create(1, create, update, draw)
    end
    local result = t_action >= 0.5
    return result
end

function load_level(new_level, previous_level)
    entities = {}
    gravity_balls = {}
    doors = {}
    collides = {}

    progress.progress = new_level

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
        transition.x = player.x
        transition.y = player.y
    end

    function find_bouncer(ball, bouncers)
        local dir = ball.customFields.Direction

        local result = {}

        if dir == "Left" or dir == "Right" then
            for b in all(bouncers) do
                if b.y == ball.y then
                    table.insert(result, b)
                end
            end
        elseif dir == "Up" or dir == "Down" then
            for b in all(bouncers) do
                if b.x == ball.x then
                    table.insert(result, b)
                end
            end
        end
        return result
    end

    for p in all(map.entities["GravityBall"]) do
        local portal = entities_factory.createGravityBall(p)
        p.on_gravity_change = on_gravity_change
        p.bouncer = find_bouncer(p, map.entities["Bouncer"])
        table.insert(entities, portal)
        table.insert(gravity_balls, portal)
    end

    local on_touch = function(box, player)
        if player.killed then
            return
        end

        player.killed = true
        player.killed_frame = -1

        -- death sequence
        sequencer.create(start_win_animation) -- start
        .next(win_circle1) -- first circle
        .next(win_animation) -- pause
        .next(win_circle2) -- second circle
        .next(restart_level) -- restart
    end

    for p in all(map.entities["Death"]) do
        local box = entities_factory.createDeath(p)
        box.on_touch = on_touch
        table.insert(entities, box)
    end

    for p in all(map.entities["Escargot"]) do
        local box = entities_factory.createEscargot(p)
        box.on_touch = on_touch
        box.bouncer = find_bouncer(p, map.entities["Bouncer"])
        table.insert(entities, box)
    end

    for p in all(map.entities["Title"]) do
        local title = new(Title, p)
        table.insert(entities, title)
    end

    for p in all(map.entities["PortalExit"]) do
        player.gravity_start = p.customFields.Gravity  
        player:restart()
    end
end

function _init()
    progress = new(Progress)

    map.level(0)
    for p in all(map.entities["Spawn"]) do
        player = player_factory.createPlayer(p)
    end

    player.start_x = player.x
    player.start_y = player.y
    
    camera = new(Camera)
    load_level()
end

function _update()
    for e in all(entities) do
        e:_update(player)
    end

    local was_jumping = player.jumping
    player:_update(collides)
    if not player.killed and not was_jumping and player.jumping then
        add_dust(player.x, player.y, player.gravity_str)
    elseif not player.killed and (ctrl.pressed(keys.left) or ctrl.pressed(keys.right)) then
        add_dust(player.x, player.y, player.gravity_str)
        sfx.play(1)

    end

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
    sequencer._update()
end

function _draw()
    draw_background()

    for e in all(entities) do
        e:_draw()
    end

    local p = spr.sheet("tiles.png")
    spr.sdraw(camera.x + progress.x, camera.y + progress.y, 40, 128, progress.width, progress.height)

    local cursor = math.floor((progress.width - 8) * progress.progress / progress.max)
    spr.sdraw(camera.x + progress.x + cursor + 4, camera.y + progress.y + 3, 56, 144, 6, 9)
    spr.sheet(p)

    particles:_draw()

    if transition ~= nil then
        transition:_draw()
    end

    player:_draw()

end
