-- Detach and initialize a Lycoris instance.
local Lycoris = { queued = false }

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Hooking
local Hooking = require("Game/Hooking")

---@module Menu
local Menu = require("Menu")

---@module Features
local Features = require("Features")

---@module Utility.ControlModule
local ControlModule = require("Utility/ControlModule")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Utility.CoreGuiManager
local CoreGuiManager = require("Utility/CoreGuiManager")

-- Lycoris maid.
local lycorisMaid = Maid.new()

-- Constants.
local LOBBY_PLACE_ID = 14067600077

-- Services.
local playersService = game:GetService("Players")

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

	if game.PlaceId ~= LOBBY_PLACE_ID then
		Hooking.init()
	end

	CoreGuiManager.set()

	PersistentData.init()

	if game.PlaceId == LOBBY_PLACE_ID then
		return Logger.warn("Script has initialized in the lobby.")
	end

	SaveManager.init()

	ModuleManager.refresh()

	ControlModule.init()

	Features.init()

	Menu.init()

	Logger.notify("Script has been initialized in %ims.", (os.clock() - startTimestamp) * 1000)

	if not PersistentData.get("fli") then
		PersistentData.set("fli", os.time())
	end

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

	Hooking.detach()

	Logger.warn("Script has been detached.")
end

-- Return Lycoris module.
return Lycoris
