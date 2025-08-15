---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(1250 + distance * 1.8, 1700)
	action._type = "Parry"
	action.hitbox = Vector3.new(100, 120, 100)
	action.name = string.format("(%.2f) Dynamic Bomb Kick Timing", distance)

	return self:action(timing, action)
end
