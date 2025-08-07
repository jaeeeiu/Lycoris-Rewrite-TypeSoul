---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local timings = {
		[1] = 1225,
	}

	local humanoid = self.entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	for idx = 1, 1 do
		local action = Action.new()
		action._when = timings[idx] or 0
		action._type = "Parry"
		action.hitbox = Vector3.new(80, 250, 80)
		action.name = string.format("(%.2f) Dynamic Ring Timing", self.track.Speed)

		if humanoid.Health <= (humanoid.MaxHealth / 2) then
			action._when /= 1.50
		end

		self:action(timing, action)
	end
end
