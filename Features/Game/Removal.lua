return LPH_NO_VIRTUALIZE(function()
	-- Removal related stuff is handled here.
	local Removal = {}

	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.Configuration
	local Configuration = require("Utility/Configuration")

	---@module Utility.OriginalStoreManager
	local OriginalStoreManager = require("Utility/OriginalStoreManager")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	-- Services.
	local runService = game:GetService("RunService")
	local players = game:GetService("Players")
	local lighting = game:GetService("Lighting")

	-- Maids.
	local removalMaid = Maid.new()

	-- Original store managers.
	local noFogMap = removalMaid:mark(OriginalStoreManager.new())
	local killBricksMap = removalMaid:mark(OriginalStoreManager.new())

	-- Signals.
	local renderStepped = Signal.new(runService.RenderStepped)
	local workspaceDescendantAdded = Signal.new(workspace.DescendantAdded)
	local workspaceDescendantRemoving = Signal.new(workspace.DescendantRemoving)

	-- Last update.
	local lastUpdate = os.clock()

	---Update no kill bricks.
	local function updateNoKillBricks()
		for _, store in next, killBricksMap:data() do
			local data = store.data
			if not data then
				continue
			end

			store:set(store.data, "CFrame", CFrame.new(math.huge, math.huge, math.huge))
		end
	end

	---Update no fog.
	local function updateNoFog()
		if lighting.FogStart == 9e9 and lighting.FogEnd == 9e9 then
			return
		end

		noFogMap:add(lighting, "FogStart", 9e9)
		noFogMap:add(lighting, "FogEnd", 9e9)

		local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
		if not atmosphere then
			return
		end

		if atmosphere.Density == 0 then
			return
		end

		noFogMap:add(atmosphere, "Density", 0)
	end

	---Update removal.
	local function updateRemoval()
		if os.clock() - lastUpdate <= 2.0 then
			return
		end

		lastUpdate = os.clock()

		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		if Configuration.expectToggleValue("NoFog") then
			updateNoFog()
		else
			noFogMap:restore()
		end

		if Configuration.expectToggleValue("NoKillBricks") then
			updateNoKillBricks()
		else
			killBricksMap:restore()
		end
	end

	---On workspace descendant added.
	---@param descendant Instance
	local function onWorkspaceDescendantAdded(descendant)
		if descendant.Name ~= "LavaBrick" or not descendant:IsA("Part") then
			return
		end

		killBricksMap:mark(descendant, "CFrame")
	end

	---On workspace descendant removing.
	---@param descendant Instance
	local function onWorkspaceDescendantRemoving(descendant)
		killBricksMap:forget(descendant)
	end

	---Initalize removal.
	function Removal.init()
		removalMaid:add(
			workspaceDescendantAdded:connect("Removal_WorkspaceDescendantAdded", onWorkspaceDescendantAdded)
		)

		removalMaid:add(
			workspaceDescendantRemoving:connect("Removal_WorkspaceDescendantRemoving", onWorkspaceDescendantRemoving)
		)

		removalMaid:add(renderStepped:connect("Removal_RenderStepped", updateRemoval))

		for _, descendant in pairs(workspace:GetDescendants()) do
			onWorkspaceDescendantAdded(descendant)
		end

		-- Log.
		Logger.warn("Removal initialized.")
	end

	---Detach removal.
	function Removal.detach()
		-- Clean.
		removalMaid:clean()

		-- Log.
		Logger.warn("Removal detached.")
	end

	-- Return Removal module.
	return Removal
end)()
