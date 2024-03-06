local Player = {
    x = 0,
    y = 0,
    width = 16,
    height = 16,
    speed = 1.5,
    y_velocity = 0,
    gravity = 0.5,
    jump_height = 100,
    jumping = false,
    x_dir = 1,
    y_dir = 0,
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
    local impulse_x = 0
    -- move horizontally
    if ctrl.pressing(keys.left) then -- move left
        self.x = self.x - self.speed
        self.x_dir = -1
    elseif ctrl.pressing(keys.right) then -- move right
        self.x = self.x + self.speed
        self.x_dir = 1
    end

    -- Apply gravity
    self.y_velocity = self.y_velocity + self.gravity
    self.y = self.y + self.y_velocity

    if ctrl.pressing(keys.space) and not self.jumping then
        self.jumping = true
        self.y_velocity = -5
        self.y = self.y - 1
    end

    -- update player position
    for c in all(collisions) do
        collide_and_slide(self, c)
    end

    -- check if grounded
    for c in all(collisions) do
        if check_collision(c, {
            x = self.x,
            y = self.y + 1,
            width = self.width,
            height = self.height
        }) then
            self.jumping = false
            self.y_velocity = 0

        end
    end
end

Player._draw = function(self)
    shape.rectf(self.x, self.y, self.width, self.height, 3)
end

local factory = {}

factory.createPlayer = function(data)
    local p = new(Player, data)
    p:_init()
    return p
end

return factory
