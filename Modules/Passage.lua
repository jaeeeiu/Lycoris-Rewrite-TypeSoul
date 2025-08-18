---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 750
	if distance >= 15 then
		action._when = math.min(800 + distance * 10, 1200)
	end
	if distance >= 16 and distance <= 17 then
		action._when = 900
	end
	action._type = "Parry"
	action.name = string.format("(%.2f) Dynamic Flowing Passage Timing", distance)
	return self:action(timing, action)
end
