---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 690
	if distance >= 15 then
		action._when = math.min(520 + distance * 12, 1400)
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 30, 60)
	action.name = string.format("(%.2f) Dynamic Evisorate Timing", distance)
	return self:action(timing, action)
end
