Window = {
	title = "",
	width = 0,
	height = 0,
}

function Window:init(width, height, title)
	self.title = title or "Shraybn"
	self.width = width
	self.height = height

	love.window.setMode(width, height, {
		vsync = false,
		resizable = true,
	})
	love.window.setTitle(self.title)
end

function Window:process_resize(width, height)
	if self.width ~= width or self.height ~= height then
		self.width = width
		self.height = height

		for _, canvas in pairs(Engine.canvases) do
			canvas:update()
		end

		Event:fire(EVENT_CODE.WINDOW_RESIZE, nil, { width, height })
	end
end

return true