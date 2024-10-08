Canvas = Object:extend()

function Canvas:new(width, height, filter)
	self.width = width
	self.height = height

	self.target = love.graphics.newCanvas(width, height)
	self.target:setFilter(filter or "linear", filter or "linear")

	self.x = 0
	self.y = 0
	self.scale = 0

	self:update()
end

function Canvas:update()
	local sx = (Window.height / self.height)
	local sy = (Window.width / self.width)
	self.scale = math.min(sx, sy)

	self.x = (Window.width / 2) - ((self.width * self.scale) / 2)
	self.y = (Window.height / 2) - ((self.height * self.scale) / 2)
end

function Canvas:start()
	love.graphics.setCanvas(self.target)
	love.graphics.clear()
end

function Canvas:finish()
	love.graphics.setCanvas()
end

function Canvas:draw()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.target, self.x, self.y, 0, self.scale, self.scale)
end
