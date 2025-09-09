---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	repeat
		task.wait()
	until self.track.TimePosition >= 0.5

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 120)
	action.name = string.format("(%.2f) Dynamic Finger Cero Timing", self.track.Speed)
	self:action(timing, action)
end
