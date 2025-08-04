---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(770 + distance * 7, 1500)
	action._type = "Parry"
	action.hitbox = Vector3.new(100, 30, 100)
	action.name = string.format("(%.2f) Dynamic Medical Rod Timing", distance)

	return self:action(timing, action)
end
