---@class Scene
Scene = Object:extend()

---@param name string
---@return Scene
function Scene:new(name)
	---@type Layer[]
	self.layers = {}
	---@type Entity[]
	self.entities = {}

	Engine.scenes[name] = self
	return Engine.scenes[name]
end

function Scene:shutdown()
	for _, layer in pairs(self.layers) do
		if layer.active and layer.detach ~= nil then
			layer.detach()
		end
	end
end

function Scene:update(dt)
	for _, layer in pairs(self.layers) do
		if layer.active and layer.update ~= nil then
			layer.update(dt)
		end
	end
end

function Scene:draw()
	for _, layer in pairs(self.layers) do
		if layer.active and layer.draw ~= nil then
			layer.draw()
		end
	end
end

---@param name string
---@param callbacks table
---@return Layer
function Scene:add_layer(name, callbacks)
	table.insert(self.layers, Layer(name, #self.layers + 1, callbacks))
	return self.layers[#self.layers]
end

---@param index integer
function Scene:remove_layer(index)
	-- Remove all entities associated with the layer.
	local i = 1
	while i <= #self.entities do
		local entity = self.entities[i]

		if entity.layer == self.layers[index] then
			print("Removing " .. tostring(entity) .. ", " .. entity.layer.name)
			table.remove(self.entities, i)
		else
			i = i + 1
		end
	end

	table.remove(self.layers, index)
end

---@param entity Entity
---@param layer Layer
function Scene:add_entity(entity, layer)
	entity.layer = layer
	entity.depth = layer.depth
	table.insert(self.entities, entity)
end

function Scene:remove_entity(index)
	table.remove(self.entities, index)
end

---@param path string
---@return Scene
function Scene.load(path)
	-- .scd are scene data files.
	local contents = Nativefs.read(path)
	local deserialized = Binser.deserialize(contents)

	return deserialized[1]
end

---@param path string
function Scene:save(path)
	local serialized = Binser.serialize(self)

	if not Nativefs.write(path, serialized, #serialized) then
		Log.error("Scene data could not be written.")
	end
end

---@return table
function Scene:entity_count()
	local counts = {}

	for _, entity in pairs(self.entities) do
		local layer = entity.layer.name

		if not counts[layer] then
			counts[layer] = 0
		end

		counts[layer] = counts[layer] + 1
	end

	return counts
end

return true
