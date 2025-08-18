return LPH_NO_VIRTUALIZE(function()
	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.Configuration
	local Configuration = require("Utility/Configuration")

	---@module Utility.CoreGuiManager
	local CoreGuiManager = require("Utility/CoreGuiManager")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	---@module Utility.Entitites
	local Entitites = require("Utility/Entitites")

	-- Monitoring module.
	local Monitoring = { subject = nil, seen = {} }

	-- Services.
	local runService = game:GetService("RunService")
	local players = game:GetService("Players")

	-- Signals.
	local renderStepped = Signal.new(runService.RenderStepped)

	-- Maids.
	local monitoringMaid = Maid.new()

	-- Instances.
	local beepSound = CoreGuiManager.imark(Instance.new("Sound"))

	-- Update limiting.
	local lastUpdateTime = os.clock()

	---Fetch name.
	local function fetchName(player)
		return string.format("(%s) %s", player:GetAttribute("CharacterName") or "Unknown Character Name", player.Name)
	end

	---Update player proximity.
	local function updatePlayerProximity()
		local proximityRange = Configuration.expectOptionValue("PlayerProximityRange") or 350
		local playersInRange = Entitites.getPlayersInRange(proximityRange)
		if not playersInRange then
			return
		end

		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		local backpack = localPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		-- Handle monitoring.
		for player, _ in next, Monitoring.seen do
			local isInPlayerRange = table.find(playersInRange, player)
			if isInPlayerRange then
				continue
			end

			local removeNotification = Monitoring.seen[player]

			removeNotification()

			Monitoring.seen[player] = nil
		end

		for _, player in next, playersInRange do
			if Monitoring.seen[player] ~= nil then
				continue
			end

			Monitoring.seen[player] =
				Logger.mnnotify("%s entered your proximity radius of %i studs.", fetchName(player), proximityRange)

			if Configuration.expectToggleValue("PlayerProximityBeep") then
				beepSound.SoundId = "rbxassetid://100849623977896"
				beepSound.PlaybackSpeed = 1
				beepSound.Volume = Configuration.expectOptionValue("PlayerProximityBeepVolume") or 0.1
				beepSound:Play()
			end
		end
	end

	---Update monitoring.
	local function updateMonitoring()
		if os.clock() - lastUpdateTime <= 2.0 then
			return
		end

		lastUpdateTime = os.clock()

		if Configuration.expectToggleValue("PlayerProximity") then
			updatePlayerProximity()
		end
	end

	---Initialize monitoring.
	function Monitoring.init()
		-- Attach.
		monitoringMaid:add(renderStepped:connect("Monitoring_OnRenderStepped", updateMonitoring))

		-- Log.
		Logger.warn("Monitoring initialized.")
	end

	---Detach spectating.
	function Monitoring.detach()
		-- Clean.
		monitoringMaid:clean()

		-- Log.
		Logger.warn("Monitoring detached.")
	end

	-- Return Monitoring module.
	return Monitoring
end)()
