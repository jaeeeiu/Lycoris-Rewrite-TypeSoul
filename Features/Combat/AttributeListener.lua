-- AttributeListener module.
local AttributeListener = { lastParry = nil, lastDash = nil }

---@modules Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Services.
local players = game:GetService("Players")

-- Attribute maid.
local attributeMaid = Maid.new()

-- Player maids.
local playerMaids = {}

---On character added.
---@param character Model
---@param maid Maid
local function onCharacterAdded(character, maid)
	local attributeChangedSignal = Signal.new(character:GetAttributeChangedSignal("CurrentState"))

	maid["CurrentStateAttributeChanged"] = attributeChangedSignal:connect(
		"AttributeListener_OnAttributeChanged",
		function(newValue)
			if newValue == "Parrying" then
				AttributeListener.lastParry = tick()
			end

			if newValue == "Flashstep" or newValue == "Dashing" then
				AttributeListener.lastDash = tick()
			end
		end
	)
end

---On character removing.
---@param character Model
---@param maid Maid
local function onCharacterRemoving(character, maid)
	maid["CurrentStateAttributeChanged"] = nil
	AttributeListener.lastParry = nil
	AttributeListener.lastDash = nil
end

---On player added.
---@param player Player
local function onPlayerAdded(player)
	local characterAddedSignal = Signal.new(player.CharacterAdded)
	local characterRemovingSignal = Signal.new(player.CharacterRemoving)
	local playerMaid = playerMaids[player] or Maid.new()

	playerMaids[player] = playerMaid

	playerMaid:add(characterAddedSignal:connect("AttributeListener_OnCharacterAdded", function(character)
		onCharacterAdded(character, playerMaid)
	end))

	playerMaid:add(characterRemovingSignal:connect("AttributeListener_OnCharacterRemoving", function(character)
		onCharacterRemoving(character, playerMaid)
	end))

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

---On player removing.
---@param player Player
local function onPlayerRemoving(player)
	local playerMaid = playerMaids[player]
	if not playerMaid then
		return
	end

	playerMaid:clean()
	playerMaids[player] = nil
end

---Can we parry?
---@return boolean
function AttributeListener.cparry()
	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character
	if not character then
		return false
	end

	return not AttributeListener.lastParry
		or tick() - AttributeListener.lastParry >= (character:GetAttribute("ParryCooldown") / 1000)
end

---Can we dash?
---@return boolean
function AttributeListener.cdash()
	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character
	if not character then
		return false
	end

	return not AttributeListener.lastDash or tick() - AttributeListener.lastDash >= (1750 / 1000)
end

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

	for _, playerMaid in next, playerMaids do
		playerMaid:clean()
	end
end

-- Return AttributeListener module.
return AttributeListener
