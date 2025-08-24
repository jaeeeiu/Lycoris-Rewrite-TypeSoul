-- Input module.
local Input = {}

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local virtualUser = game:GetService("VirtualUser")
local players = game:GetService("Players")

-- Maids.
local inputMaid = Maid.new()

---Input initialization.
function Input.init()
	local localPlayer = players.LocalPlayer
	local idledSignal = Signal.new(localPlayer.Idled)

	inputMaid:add(idledSignal:connect("Input_PlayerIdled", function()
		if not Configuration.expectToggleValue("AntiAFK") then
			return
		end

		virtualUser:CaptureController()
		virtualUser:ClickButton2(Vector2.new())
	end))
end

---Input detach.
function Input.detach()
	inputMaid:clean()
end

-- Return Input module.
return Input
