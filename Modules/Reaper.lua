---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(300 + distance * 6, 700)
	action._type = "Parry"
	action.hitbox = Vector3.new(18, 15, 25)
	action.name = string.format("(%.2f) Dynamic Reaper's Hook Timing", distance)

	return self:action(timing, action)
end
