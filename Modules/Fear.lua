---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(630 + distance * 13, 1800)
	action._type = "Parry"
	action.hitbox = Vector3.new(55, 55, 55)
	action.name = string.format("(%.2f) Dynamic Fear Timing", distance)

	return self:action(timing, action)
end
