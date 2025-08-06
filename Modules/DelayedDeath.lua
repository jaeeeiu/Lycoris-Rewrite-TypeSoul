---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(750 + distance * 5.5, 1200)
	action._type = "Parry"
	action.hitbox = Vector3.new(70, 30, 100)
	action.name = string.format("(%.2f) Dynamic Delayed Death Timing", distance)

	return self:action(timing, action)
end
