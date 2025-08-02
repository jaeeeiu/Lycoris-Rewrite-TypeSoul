---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Features.Visuals.Objects.ModelESP
local ModelESP = require("Features/Visuals/Objects/ModelESP")

---@module Features.Visuals.Objects.PartESP
local PartESP = require("Features/Visuals/Objects/PartESP")

---@module Features.Visuals.Objects.MobESP
local MobESP = require("Features/Visuals/Objects/MobESP")

---@module Features.Visuals.Objects.PlayerESP
local PlayerESP = require("Features/Visuals/Objects/PlayerESP")

---@module Features.Visuals.Group
local Group = require("Features/Visuals/Group")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

-- Visuals module.
local Visuals = { currentBuilderData = nil }

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local visualsMaid = Maid.new()

-- Groups.
local groups = {}

---Update visuals.
local updateVisuals = LPH_NO_VIRTUALIZE(function()
	for _, group in next, groups do
		group:update()
	end
end)

---Emplace object.
---@param instance Instance
---@param object ModelESP|PartESP
local emplaceObject = LPH_NO_VIRTUALIZE(function(instance, object)
	local group = groups[object.identifier] or Group.new(object.identifier)

	group:insert(instance, object)

	groups[object.identifier] = group
end)

---On Entities ChildAdded.
---@param child Instance
local onEntitiesChildAdded = LPH_NO_VIRTUALIZE(function(child)
	if players:GetPlayerFromCharacter(child) then
		return
	end

	-- safeguard lol
	if players:FindFirstChild(child.Name) then
		return
	end

	return emplaceObject(child, MobESP.new("Mob", child, child:GetAttribute("EntityType") or child.Name))
end)

---On instance removing.
---@param inst Instance
local onInstanceRemoving = LPH_NO_VIRTUALIZE(function(inst)
	for _, group in next, groups do
		local object = group:remove(inst)
		if not object then
			continue
		end

		object:detach()
	end
end)

---On player added.
---@param player Player
local onPlayerAdded = LPH_NO_VIRTUALIZE(function(player)
	if player == players.LocalPlayer then
		return
	end

	local characterAdded = Signal.new(player.CharacterAdded)
	local characterRemoving = Signal.new(player.CharacterRemoving)
	local playerDestroying = Signal.new(player.Destroying)

	local characterAddedId = nil
	local characterRemovingId = nil
	local playerDestroyingId = nil

	characterAddedId = visualsMaid:add(characterAdded:connect("Visuals_OnCharacterAdded", function(character)
		emplaceObject(player, PlayerESP.new("Player", player, character))
	end))

	characterRemovingId = visualsMaid:add(characterRemoving:connect("Visuals_OnCharacterRemoving", function()
		onInstanceRemoving(player)
	end))

	playerDestroyingId = visualsMaid:add(playerDestroying:connect("Visuals_OnPlayerDestroying", function()
		visualsMaid[characterAddedId] = nil
		visualsMaid[characterRemovingId] = nil
		visualsMaid[playerDestroyingId] = nil
	end))

	local character = player.Character
	if not character then
		return
	end

	emplaceObject(player, PlayerESP.new("Player", player, character))
end)

---Create children listener.
---@param instance Instance
---@param identifier string
---@param addedCallback function
---@param removingCallback function
local createChildrenListener = LPH_NO_VIRTUALIZE(function(instance, identifier, addedCallback, removingCallback)
	local childAdded = Signal.new(instance.ChildAdded)
	local childRemoved = Signal.new(instance.ChildRemoved)

	visualsMaid:add(childAdded:connect(string.format("Visuals_%sOnChildAdded", identifier), addedCallback))
	visualsMaid:add(childRemoved:connect(string.format("Visuals_%sOnChildRemoved", identifier), removingCallback))

	Profiler.run(string.format("Visuals_%sAddInitialChildren", identifier), function()
		for _, child in next, instance:GetChildren() do
			addedCallback(child)
		end
	end)
end)

---Initialize Visuals.
function Visuals.init()
	local ents = workspace:WaitForChild("Entities")

	createChildrenListener(ents, "Entities", onEntitiesChildAdded, onInstanceRemoving)
	createChildrenListener(players, "Players", onPlayerAdded, onInstanceRemoving)

	visualsMaid:add(renderStepped:connect("Visuals_RenderStepped", updateVisuals))

	Logger.warn("Visuals initialized.")
end

-- Detach Visuals.
function Visuals.detach()
	for _, group in next, groups do
		group:detach()
	end

	visualsMaid:clean()

	Logger.warn("Visuals detached.")
end

-- Return Visuals module.
return Visuals
