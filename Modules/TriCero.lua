---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	task.wait(0.1)
	local action = Action.new()
	action._when = (700 * 2.00) / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 20, 150)
	action.name = string.format("(%.2f) Dynamic Tri Cero Timing", self.track.Speed)
	return self:action(timing, action)
end
