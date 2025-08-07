---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	task.wait(0.1)
	local action = Action.new()
	action._when = (470 * 0.75) / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(13, 13, 14)
	action.name = string.format("(%.2f) Dynamic Muramasa Timing", self.track.Speed)
	return self:action(timing, action)
end
