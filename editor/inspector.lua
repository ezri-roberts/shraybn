local ffi = require("ffi")

Inspector = {
	item = nil, -- The "item" we are inspecting.
	type = nil,
	viewer_width = 256,
	viewer_height = 384,
	viewer_image = nil,
}

Inspector.bk_grid = love.graphics.newImage("editor/bk_grid.png")
Inspector.viewer_canvas = love.graphics.newCanvas(Inspector.viewer_width, Inspector.viewer_height)

local function get_mem(bytes)
	local number = nil
	local suffix = "B"

	if bytes >= math.pow(10, 9) then
		suffix = "GB"
		number = bytes / math.pow(10, 9)
	elseif bytes >= math.pow(10, 6) then
		suffix = "MB"
		number = bytes / math.pow(10, 6)
	elseif bytes >= 1000 then
		suffix = "KB"
		number = bytes / 1000
	end

	return number .. suffix
end

---@param type string
---| "layer"
---| "image"
---@param item any
function Inspector:inspect(type, item)
	self.item = item
	self.type = type
end

function Inspector:image(image)
	local win_width = Imgui.GetContentRegionAvail().x

	-- Resize the canvas if needed.
	if self.viewer_width ~= win_width then
		self.viewer_width = win_width
		if self.viewer_width > 0 and self.viewer_height > 0 then
			self.viewer_canvas = love.graphics.newCanvas(self.viewer_width, self.viewer_height)
		end
	end

	love.graphics.setCanvas(self.viewer_canvas)

	local tile_size = 32
	local x_tiles = math.ceil(self.viewer_width / tile_size)
	local y_tiles = math.ceil(self.viewer_height / tile_size)

	-- Draw grid to canvas.
	for x = 1, x_tiles, 1 do
		for y = 1, y_tiles, 1 do
			local pos_x = (x - 1) * tile_size
			local pos_y = (y - 1) * tile_size

			love.graphics.draw(self.bk_grid, pos_x, pos_y)
		end
	end

	local res = image.resource

	local scale_x = self.viewer_canvas:getWidth() / res:getWidth()
	local scale_y = self.viewer_canvas:getHeight() / res:getHeight()
	local scale = math.min(scale_x, scale_y)

	local width = res:getWidth() * scale
	local height = res:getHeight() * scale
	local x = (self.viewer_canvas:getWidth() / 2) - (width / 2)
	local y = (self.viewer_canvas:getHeight() / 2) - (height / 2)

	love.graphics.draw(res, x, y, 0, scale)

	love.graphics.setCanvas()

	Imgui.TextWrapped(image.path)

	local size = Imgui.ImVec2_Float(self.viewer_canvas:getDimensions())
	Imgui.Image(self.viewer_canvas, size)
end

function Inspector:layer()
	local layer = self.item

	local first = layer.type:sub(1, 1):upper()
	local last = layer.type:sub(2, #layer.type)
	local str = first .. last
	Imgui.Text(str .. " layer.")

	if layer.type == "image" then
		if not layer.image then
			Imgui.Text("No Image.")
		end

		if Imgui.BeginDragDropTarget() then
			local payload = Imgui.AcceptDragDropPayload("DRAG_DROP_FILE")
			if Imgui.IsMouseReleased_Nil(0) then
				if payload then
					local data = ffi.string(payload.Data)
					local key = Util.path_to_key(data)
					layer.image = Assets:get("image", key)
				end
			end

			Imgui.EndDragDropTarget()
		end

		if layer.image then
			self:image(layer.image)
		end
	end
end

function Inspector:display()
	Imgui.Begin("Inspector", nil)

	if self.item then
		if self.type == "image" then
			self:image(self.item)
		elseif self.type == "layer" then
			self:layer()
		end
	end

	Imgui.End()
end
