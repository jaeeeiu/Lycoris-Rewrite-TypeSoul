---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(360 + distance * 17, 1500)
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 15, 70)
	action.name = string.format("(%.2f) Dynamic Water X Timing", distance)

	return self:action(timing, action)
end
