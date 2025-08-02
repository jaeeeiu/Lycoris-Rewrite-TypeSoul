-- Features related stuff is handled here.
local Features = {}

---@module Features.Game.Movement
local Movement = require("Features/Game/Movement")

---@module Features.Visuals.Visuals
local Visuals = require("Features/Visuals/Visuals")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Features.Combat.Defense
local Defense = require("Features/Combat/Defense")

---@module Features.Game.AnimationVisualizer
local AnimationVisualizer = require("Features/Game/AnimationVisualizer")

---Initialize features.
---@note: Careful with features that have entire return LPH_NO_VIRTUALIZE(function() blocks. We assume that we don't care about what's placed in there.
function Features.init()
	Defense.init()
	Visuals.init()
	Movement.init()

	-- Only initialize if we're a builder.
	if not armorshield or armorshield.current_role == "builder" then
		AnimationVisualizer.init()
	end

	Logger.warn("Features initialized.")
end

---Detach features.
function Features.detach()
	-- Only detach if we're a builder.
	if not armorshield or armorshield.current_role == "builder" then
		AnimationVisualizer.detach()
	end

	Defense.detach()
	Movement.detach()
	Visuals.detach()

	Logger.warn("Features detached.")
end

-- Return Features module.
return Features
