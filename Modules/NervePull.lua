---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = math.min(385 + distance * 15, 1700)
	action._type = "Start Block"
	action.hitbox = Vector3.new(55, 20, 70)
	action.name = string.format("(%.2f) Dynamic Nerve Pull Timing", distance)
	self:action(timing, action)

	local action2 = Action.new()
	action2._when = 1500
	action2._type = "End Block"
	action2.hitbox = Vector3.new(120, 120, 120)
	action2.name = string.format("(2) (%.2f) Dynamic Timing", distance)
	self:action(timing, action2)
end
