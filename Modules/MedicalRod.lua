---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()

	-- pattern seems to be for every distance increment of 12 += 50
	-- 3 : 650
	-- 9-11 : 650
	-- 11-23 : 700
	-- 23-34: 750

	action._when = 650

	if distance >= 12 then
		action._when += math.floor(distance / 12) * 50
	end

	action._type = "Parry"
	action.hitbox = Vector3.new(100, 30, 300)
	action.name = string.format("(%.2f) Dynamic Medical Rod Timing", distance)

	return self:action(timing, action)
end
