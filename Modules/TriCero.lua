---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	task.wait(0.1)
	local speed = self.track.Speed
	local action = Action.new()
	action._when = 700
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 20, 150)
	action.name = string.format("(%.2f) Dynamic Tri Cero Timing", speed)

	if speed > 1.0 then
		action._when = 600
	end

	return self:action(timing, action)
end
