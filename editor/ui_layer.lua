local dockspace = require("editor.dockspace")

local function ui_event(code, sender, listener, data)
	return ImguiEvent(code, data)
end

local function ui_attach()
	Imgui.love.Init()

	local io = Imgui.GetIO()
	io.ConfigFlags = bit.bor(io.ConfigFlags, Imgui.ImGuiConfigFlags_DockingEnable)

	Event:register_category(EVENT_CATEGORY.INPUT, nil, ui_event)
end

local function ui_detach()
	Imgui.love.Shutdown()
end

local function ui_update(dt)
	Imgui.love.Update(dt)
	Imgui.NewFrame()
end

local function ui_draw()
	dockspace()

	Imgui.Begin("Assets", nil)

	Imgui.End()

	-- code to render imgui
	Imgui.Render()
	Imgui.love.RenderDrawLists()
end

Engine:new_layer("ui_layer", {
	attach = ui_attach,
	detach = ui_detach,
	update = ui_update,
	draw = ui_draw,
	event = ui_event,
})