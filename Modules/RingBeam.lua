---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 2250
	action._type = "Parry"
	action.hitbox = Vector3.new(80, 250, 80)
	action.name = string.format("(Parry) (%.2f) Dynamic Ring Timing", self.track.Speed)

	if self.track.Speed >= 1.45 and self.track.Speed <= 1.55 then
		action._when = 1525
	end

	self:action(timing, action)

	local secondAction = Action.new()
	secondAction._when = 2775
	secondAction._type = "Parry"
	secondAction.hitbox = Vector3.new(80, 250, 80)
	secondAction.name = string.format("(Fire Parry) (%.2f) Dynamic Ring Timing", self.track.Speed)

	if self.track.Speed >= 1.45 and self.track.Speed <= 1.55 then
		secondAction._when = 2025
	end

	self:action(timing, secondAction)
end
