---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = (390 * 0.75) / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(13, 13, 14)
	action.name = string.format("(%.2f) Dynamic Muramasa Timing", self.track.Speed)
	return self:action(timing, action)
end
