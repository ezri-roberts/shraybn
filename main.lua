require("engine")

local function mouse_x(code, sender, listener, data)
	return false
end
local function mouse_y(code, sender, listener, data)
	return true
end

-- local function l_attach()
-- 	print("Attached")
-- end

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
	if not Engine.init() then
		Log.fatal("Engine failed to initialize")
	end
	Window:init(1280, 720)

	Event:register(EVENT_CODE.MOUSE_MOVE, nil, mouse_x)
	Event:register(EVENT_CODE.MOUSE_MOVE, nil, mouse_y)
	-- Event:register(EVENT_CODE.MOUSE_MOVE, nil, Mouse_y)

	-- Engine:new_layer("test_layer", {
	-- 	attach = l_attach,
	-- })
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
	if Input:button_pressed(MOUSE_BUTTON.LEFT) then
		print("LEFT")
	end

	if Input:key_pressed("a") then
		print("A")
	end

	Engine:update(dt)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
	Engine.draw()
end
