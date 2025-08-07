---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 420
	if distance >= 18 then
		action._when = 440
	end
	if distance >= 21 then
		action._when = 660
	end
	if distance >= 42 then
		action._when = 900
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 20, 70)
	action.name = string.format("(%.2f) Dynamic Justice Timing", distance)
	return self:action(timing, action)
end
