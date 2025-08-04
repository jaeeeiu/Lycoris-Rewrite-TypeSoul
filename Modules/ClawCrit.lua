---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 350
	if distance >= 12 then
		action._when = 550
	end
	if distance >= 16 then
		action._when = 620
	end
	if distance >= 21 then
		action._when = 680
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 25)
	action.name = string.format("(%.2f) Dynamic Claw Critical Timing", distance)
	return self:action(timing, action)
end
