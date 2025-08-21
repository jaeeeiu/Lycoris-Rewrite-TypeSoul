---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 400
	if distance >= 9 then
		action._when = math.min(540 + distance * 13, 1200)
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(14, 15, 20)
	action.name = string.format("(%.2f) Dynamic Confliction Timing", distance)
	return self:action(timing, action)
end
