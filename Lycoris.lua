-- Detach and initialize a Lycoris instance.
local Lycoris = { queued = false }

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Menu
local Menu = require("Menu")

---@module Features
local Features = require("Features")

---@module Utility.ControlModule
local ControlModule = require("Utility/ControlModule")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Utility.CoreGuiManager
local CoreGuiManager = require("Utility/CoreGuiManager")

---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

-- Lycoris maid.
local lycorisMaid = Maid.new()

-- Constants.
local LOBBY_PLACE_ID = 14067600077

-- Services.
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Timestamp.
local startTimestamp = os.clock()

---Initialize instance.
function Lycoris.init()
	local localPlayer = nil

	repeat
		task.wait()
	until game:IsLoaded()

	repeat
		localPlayer = playersService.LocalPlayer
	until localPlayer ~= nil

	PersistentData.init()

	if script_key and queue_on_teleport and not Lycoris.queued and not no_queue_on_teleport then
		-- String.
		local scriptKeyQueueString = string.format("script_key = '%s'", script_key or "N/A")
		local loadStringQueueString =
			'loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/0216eb5f95556e660be56009441409ae.lua"))()'

		-- Queue.
		queue_on_teleport(scriptKeyQueueString .. "\n" .. loadStringQueueString)

		-- Mark.
		Lycoris.queued = true

		-- Warn.
		Logger.warn("Script has been queued for next teleport.")
	else
		-- Fail.
		Logger.warn("Script has failed to queue on teleport because Luarmor internals or the function do not exist.")
	end

	local tslot = PersistentData.get("tslot")
	local tdestination = PersistentData.get("tdestination")

	if game.PlaceId == LOBBY_PLACE_ID and tslot and tdestination then
		local remotes = replicatedStorage:WaitForChild("Remotes")
		local chooseSlotRemote = remotes:WaitForChild("ChooseSlot")
		local teleportRemote = remotes:WaitForChild("Teleport")

		chooseSlotRemote:InvokeServer(tslot, nil)
		teleportRemote:InvokeServer({ teleportTo = tdestination })
	end

	if game.PlaceId == LOBBY_PLACE_ID then
		return Logger.warn("Script has initialized in the lobby.")
	end

	local remotes = replicatedStorage:WaitForChild("Remotes")
	local vastoVfx = remotes:FindFirstChild("VastoVfx")

	if vastoVfx then
		vastoVfx:Destroy()
	end

	Logger.warn("Anticheat has been successfully penetrated.")

	CoreGuiManager.set()

	SaveManager.init()

	ModuleManager.refresh()

	ControlModule.init()

	Features.init()

	Menu.init()

	Logger.notify("Script has been initialized in %ims.", (os.clock() - startTimestamp) * 1000)

	local playerRemovingSignal = lycorisMaid:mark(Signal.new(playersService.PlayerRemoving))

	playerRemovingSignal:connect("Lycoris_OnLocalPlayerRemoved", function(player)
		if player ~= playersService.LocalPlayer then
			return
		end

		-- Auto-save.
		local initial, result = SaveManager.autosave()

		-- Make a marker to show that we were able to autosave properly.
		pcall(function()
			writefile(
				"Lycoris_LastAutoSaveTimestamp.txt",
				string.format(
					"%s : %s the config file '%s' with result %i after player removal.",
					DateTime.now():FormatLocalTime("LLLL", "en-us"),
					initial and "(1) Attempted to save" or "(2) Attempted to save",
					SaveManager.llcn or "N/A",
					result
				)
			)
		end)
	end)
end

---Detach instance.
function Lycoris.detach()
	lycorisMaid:clean()

	ModuleManager.detach()

	SaveManager.autosave()

	Menu.detach()

	ControlModule.detach()

	Features.detach()

	CoreGuiManager.clear()

	Logger.warn("Script has been detached.")
end

-- Return Lycoris module.
return Lycoris
