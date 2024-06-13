local function scene_tabs()
	if Imgui.BeginTabBar("##scene_tabs") then
		if not Editor.current_scene then
			if Imgui.BeginTabItem("[empty]") then
				Imgui.EndTabItem()
			end
		end

		for k, scene in pairs(Editor.open_scenes) do
			local text = scene.name
			if scene.unsaved == true then
				text = text .. "(*)"
			end

			if Imgui.BeginTabItem(text) then
				Editor.current_scene = scene
				Imgui.EndTabItem()
			end
		end

		Imgui.EndTabBar()
	end
end

return scene_tabs
