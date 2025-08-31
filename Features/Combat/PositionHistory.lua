-- PositionHistory module.
local PositionHistory = {}

-- Histories table.
local histories = {}

-- Max history seconds.
local MAX_HISTORY_SECS = 3.0

---Add an entry to the history list.
---@param idx any
---@param position CFrame
---@param timestamp number
function PositionHistory.add(idx, position, timestamp)
	local history = histories[idx] or {}

	if not histories[idx] then
		histories[idx] = history
	end

	history[#history + 1] = {
		position = position,
		timestamp = timestamp,
	}

	while true do
		local tail = history[1]
		if not tail then
			break
		end

		if tick() - tail.timestamp <= MAX_HISTORY_SECS then
			break
		end

		table.remove(history, 1)
	end
end

---Get the horizontal angular velocity (yaw rate) for a current index.
---@param index any
---@return number?
function PositionHistory.yrate(index)
	local history = histories[index]
	if not history or #history < 2 then
		return nil
	end

	local latest = history[#history]
	local previous = history[#history - 1]

	local dt = latest.timestamp - previous.timestamp
	if dt <= 1e-4 then
		return nil
	end

	local prevLook = Vector3.new(previous.position.LookVector.X, 0, previous.position.LookVector.Z).Unit
	local latestLook = Vector3.new(latest.position.LookVector.X, 0, latest.position.LookVector.Z).Unit

	local dot = prevLook:Dot(latestLook)
	local crossY = prevLook:Cross(latestLook).Y
	local angle = math.atan2(crossY, dot)

	return angle / dt
end

---Divides the history into a number of equal steps and returns the position at each step.
---@param idx any
---@param steps number
---@param phds number History second limit for past hitbox detection.
---@return CFrame[]?
function PositionHistory.stepped(idx, steps, phds)
	local history = histories[idx]
	if not history or #history == 0 then
		return nil
	end

	if not steps or steps <= 0 then
		return nil
	end

	local vhistory = {}

	for _, data in next, history do
		if tick() > data.timestamp + phds then
			break
		end

		vhistory[#vhistory + 1] = data.position
	end

	local chunks = {}
	local csize = #vhistory / steps

	for hidx = 1, steps do
		local data = vhistory[math.floor(hidx * csize)]
		if not data then
			break
		end

		chunks[#chunks + 1] = data.position
	end

	return chunks
end
---Get closest position (in time) to a timestamp.
---@param idx any
---@param timestamp number
---@return CFrame?
function PositionHistory.closest(idx, timestamp)
	local closestDelta = nil
	local closestPosition = nil

	for _, data in next, histories[idx] do
		local delta = math.abs(timestamp - data.timestamp)

		if closestDelta and delta >= closestDelta then
			continue
		end

		closestPosition = data.position
		closestDelta = delta
	end

	return closestPosition
end

-- Return PositionHistory module.
return PositionHistory
