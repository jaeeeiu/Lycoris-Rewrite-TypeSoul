---@note: Typed object that represents information. It's not really a true class but just needs to store the correct data.
---@class RepeatInfo
---@field track AnimationTrack?
---@field timing Timing
---@field start number
---@field index number
local RepeatInfo = {}
RepeatInfo.__index = RepeatInfo

---Create new RepeatInfo object.
---@param timing Timing
---@return RepeatInfo
function RepeatInfo.new(timing)
	local self = setmetatable({}, RepeatInfo)
	self.track = nil
	self.timing = timing
	self.start = os.clock()
	self.index = 0
	return self
end

-- Return RepeatInfo module.
return RepeatInfo
