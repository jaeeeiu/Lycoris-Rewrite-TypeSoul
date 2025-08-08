---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	task.wait(0.1)
	local speed = self.track.Speed
	local action = Action.new()
	action._when = 640
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 16)
	action.name = string.format("(1) (%.2f) Dynamic Sweep Timing", speed)
	self:action(timing, action)

	if speed > 1.1 then
		action._when = 512
	end

	local action2 = Action.new()
	action2._when = 1165
	action2._type = "Parry"
	action2.hitbox = Vector3.new(16, 15, 16)
	action2.name = string.format("(2) (%.2f) Dynamic Sweep Timing", speed)
	self:action(timing, action2)

	if speed > 1.1 then
		action._when = 932
	end

	local action3 = Action.new()
	action3._when = 1760
	action3._type = "Parry"
	action3.hitbox = Vector3.new(15, 15, 20)
	action3.name = string.format("(2) (%.2f) Dynamic Sweep Timing", speed)
	self:action(timing, action3)

	if speed > 1.1 then
		action._when = 1408
	end
end
