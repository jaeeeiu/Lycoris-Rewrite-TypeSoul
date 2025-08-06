---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(600 + distance * 6.5, 1400)
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 20, 30)
	action.name = string.format("(%.2f) Dynamic Bala Drive Timing", distance)

	return self:action(timing, action)
end
