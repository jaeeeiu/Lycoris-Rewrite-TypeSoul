---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 25, 170)
	action.name = "Keyframe Action"
	return self:akeyframe(action, 1.31)
end
