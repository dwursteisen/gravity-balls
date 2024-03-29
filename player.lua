local Player = {
    x = 0,
    y = 0,
    width = 8,
    height = 8,
    speed = 1.5,
    y_velocity = 0,
    gravity_str = "Down",
    gravity_y = 0.5, -- actual gravity in the game
    gravity_x = 0,
    gravity_y_sign = 1, -- sign of the gravity (-1 or 1). Might be equal to 0 if no gravity
    gravity_x_sign = 0,
    jump_height = 100,
    jumping = false,
    stop_jumping = -1,
    x_dir = 1,
    y_dir = 0,
    stick_to = nil,
    killed = false
}

Player._init = function(self)

end

-- Function to check collision between two rectangles
function check_collision(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and rect1.x + rect1.width > rect2.x and rect1.y < rect2.y + rect2.height and
               rect1.y + rect1.height > rect2.y
end

-- Function to resolve collision and slide
function collide_and_slide(object, obstacle)
    if check_collision(object, obstacle) then
        local overlapX = math.min(object.x + object.width, obstacle.x + obstacle.width) - math.max(object.x, obstacle.x)
        local overlapY = math.min(object.y + object.height, obstacle.y + obstacle.height) -
                             math.max(object.y, obstacle.y)

        if overlapX < overlapY then
            if object.x < obstacle.x then
                object.x = object.x - overlapX
            else
                object.x = object.x + overlapX
            end
        else
            if object.y < obstacle.y then
                object.y = object.y - overlapY
            else
                object.y = object.y + overlapY
            end
        end
    end
end

Player._update = function(self, collisions, platforms)
    if self.stick_to ~= nil then
        self.x = self.x - self.stick_to.dt_x
        self.y = self.y - self.stick_to.dt_y
    end
    --
    if not self.transition then
        -- move horizontally
        if not self.killed and ctrl.pressing(keys.left) then -- move left
            self.x = self.x - self.speed
            self.x_dir = -1
        elseif not self.killed and ctrl.pressing(keys.right) then -- move right
            self.x = self.x + self.speed
            self.x_dir = 1
        end
    end

    -- Apply gravity
    -- TODO: apply x velocity with x_gravity
    if not self.killed then 
        self.y_velocity = math.clamp(-6, self.y_velocity + self.gravity_y, 6)
        self.y = self.y + self.y_velocity * 0.5
    end

    if self.stop_jumping > 4 then
        self.stop_jumping = -2
    elseif self.stop_jumping >= 0 then
        self.stop_jumping = self.stop_jumping + 0.5
    end

    if self.killed then
        self.killed_frame = self.killed_frame + 0.5
        if self.killed_frame > 7 then
            self.killed_frame = 5
        end
    end

    local was_jumping = self.jumping

    if self.jumping == false and self.killed == false and (ctrl.pressing(keys.space)) then

        self.jumping = true
        self.stop_jumping = -1
        self.y_velocity = -10 * self.gravity_y_sign
        self.y = self.y - 1 * self.gravity_y_sign
        if self.jumping then
            sfx.play(0)
        end
    end

    -- update player position
    for c in all(collisions) do
        collide_and_slide(self, c)
    end

    if was_jumping and self.jumping then

        -- check if grounded
        for c in all(collisions) do
            if check_collision(c, {
                x = self.x,
                y = self.y + 2 * self.gravity_y_sign,
                width = self.width,
                height = self.height
            }) then
                self.jumping = false
                if self.stop_jumping == -1 then
                    self.stop_jumping = 0
                end
                self.y_velocity = 0
                if c.moveable then
                    self.stick_to = c
                end

            end
        end
    end

    self.stick_to = nil
end

local invert_h = {
    Down = false,
    Up = true,
    Left = false,
    Right = false
}

local invert_v = {
    Down = false,
    Up = true,
    Left = false,
    Right = false
}

Player._draw = function(self)
    local current = spr.sheet("wizard.png")
    -- shape.rectf(self.x, self.y, self.width, self.height, 3)
    if self.jumping then
        spr.draw(36 + (tiny.frame * 0.2) % 4, self.x, self.y, self.x_dir ~= 1, invert_h[self.gravity_str])
    elseif self.killed then
        local frame = 45 + self.killed_frame
        spr.draw(frame, self.x, self.y, self.x_dir ~= 1, invert_h[self.gravity_str])
    elseif self.stop_jumping >= 0 then
        spr.draw(math.floor(40 + self.stop_jumping), self.x, self.y, self.x_dir ~= 1, invert_h[self.gravity_str])
    else
        local id = 19 + (tiny.frame * 0.2) % 16
        spr.draw(id, self.x, self.y, self.x_dir ~= 1, invert_h[self.gravity_str])
    end

    spr.sheet(current)
end

Player.restart = function(self)
    self.killed = false
    self.x = self.start_x
    self.y = self.start_y

    self.y_velocity = 0
    self.gravity_str = "Down"
    self.gravity_y = 0.5 -- actual gravity in the game
    self.gravity_x = 0
    self.gravity_y_sign = 1 -- sign of the gravity (-1 or 1). Might be equal to 0 if no gravity
    self.gravity_x_sign = 0
    self.jumping = false
    self.stop_jumping = -1
    self.x_dir = 1
    self.y_dir = 0
    self.stick_to = nil
    self:update_gravity(self.gravity_start)
end

Player.update_gravity = function(self, gravity)
    self.gravity_str = gravity
    if gravity == "Up" then
        self.gravity_sign = -1
        self.gravity_y = -0.5
    else
        self.gravity_sign = 1
        self.gravity_y = 0.5
    end
end

local factory = {}

factory.createPlayer = function(data)
    local p = new(Player, data)
    p.start_x = p.x
    p.start_y = p.y
    p:_init()
    return p
end

return factory
