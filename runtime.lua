require("engine")
require("engine.imgui")

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
	Window:init(1280, 720)

	Scene("default_scene")
	Engine:set_scene("default_scene")

	require("ui_layer")
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
	Engine:update(dt)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
	Engine:draw()
end

---@diagnostic disable-next-line: duplicate-set-field
function love.quit()
	Engine:shutdown()
end
