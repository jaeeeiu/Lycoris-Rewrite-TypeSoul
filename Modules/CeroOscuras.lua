---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	repeat
		task.wait()
	until self.track.TimePosition >= 1.39

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(35, 25, 120)
	action.name = string.format("(%.2f) Dynamic Cero Oscuras Timing", self.track.Speed)
	self:action(timing, action)
end
