---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(560 + distance * 11, 1300)
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 25, 60)
	action.name = string.format("(%.2f) Dynamic Power Timing", distance)

	return self:action(timing, action)
end
