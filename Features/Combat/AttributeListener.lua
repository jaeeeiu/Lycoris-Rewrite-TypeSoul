-- AttributeListener module.
local AttributeListener = {}

---@modules Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Services.
local players = game:GetService("Players")

-- Attribute maid.
local attributeMaid = Maid.new()

---On character added.
local function onCharacterAdded() end

---On player added.
local function onPlayerAdded() end

---On player removing.
local function onPlayerRemoving() end

---Initialize AttributeListener module.
function AttributeListener.init()
	local playerAddedSignal = Signal.new(players.PlayerAdded)
	local playerRemovingSignal = Signal.new(players.PlayerRemoving)

	attributeMaid:add(playerAddedSignal:connect("AttributeListener_OnPlayerAdded", onPlayerAdded))
	attributeMaid:add(playerRemovingSignal:connect("AttributeListener_OnPlayerRemoving", onPlayerRemoving))
end

---Detach AttributeListener module.
function AttributeListener.detach()
	attributeMaid:clean()
end

-- Return AttributeListener module.
return AttributeListener
