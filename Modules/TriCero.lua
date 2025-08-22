---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	repeat
		task.wait()
	until self.track.TimePosition >= 1.38

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 150)
	action.name = string.format("(%.2f) Dynamic Tri Cero Timing", self.track.Speed)
	self:action(timing, action)
end
