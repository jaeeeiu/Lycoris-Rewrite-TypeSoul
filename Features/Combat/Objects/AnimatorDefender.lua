---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.Timings.PlaybackData
local PlaybackData = require("Game/Timings/PlaybackData")

---@module GUI.Library
local Library = require("GUI/Library")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = require("Features/Combat/Objects/RepeatInfo")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field kfmaid Maid
---@field heffects Instance[]
---@field keyframes Action[]
---@field offset number?
---@field timing AnimationTiming?
---@field pbdata table<AnimationTrack, PlaybackData> Playback data to be recorded.
---@field rpbdata table<string, PlaybackData> Recorded playback data. Optimization so we don't have to constantly reiterate over recorded data.
---@field manimations table<number, Animation>
---@field track AnimationTrack? Don't be confused. This is the **valid && last** animation track played.
---@field maid Maid This maid is cleaned up after every new animation track. Safe to use for on-animation-track setup.
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender
AnimatorDefender.__type = "Animation"

-- Services.
local players = game:GetService("Players")

-- Constants.
local MAX_REPEAT_TIME = 5.0

-- Memory table.
local kfMemoryTable = {}

---Is animation stopped? Made into a function for de-duplication.
---@param self AnimatorDefender
---@param track AnimationTrack
---@param timing AnimationTiming
---@return boolean
AnimatorDefender.stopped = LPH_NO_VIRTUALIZE(function(self, track, timing)
	if not timing.iae and not track.IsPlaying then
		return true, self:notify(timing, "Animation stopped playing.")
	end

	if timing.iae and not timing.ieae and not track.IsPlaying and track.TimePosition < track.Length then
		return true, self:notify(timing, "Animation stopped playing early.")
	end
end)

---Repeat conditional. Extra parameter 'track' added on.
---@param self AnimatorDefender
---@param info RepeatInfo
---@return boolean
AnimatorDefender.rc = LPH_NO_VIRTUALIZE(function(self, info)
	---@note: There are cases where we might not have a track. If it's not handled properly, it will throw an error.
	-- Perhaps, the animation can end and we're handling a different repeat conditional.
	if not info.track then
		return Logger.warn(
			"(%s) Did you forget to pass the track? Or perhaps you forgot to place a hook before using this function.",
			PP_SCRAMBLE_STR(info.timing.name)
		)
	end

	if self:stopped(info.track, info.timing) then
		return false
	end

	if info.timing.iae and os.clock() - info.start >= ((info.timing.mat / 1000) or MAX_REPEAT_TIME) then
		return self:notify(info.timing, "Max animation timeout exceeded.")
	end

	return true
end)

---Check if we're in a valid state to proceed with the action.
---@param self AnimatorDefender
---@param timing AnimationTiming
---@param action Action
---@return boolean
AnimatorDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not Defender.valid(self, timing, action) then
		return false
	end

	if not self.track then
		return self:notify(timing, "No current track.")
	end

	if not self.entity then
		return self:notify(timing, "No entity found.")
	end

	local target = self:target(self.entity)
	if not target then
		return self:notify(timing, "Not a viable target.")
	end

	local root = self.entity:FindFirstChild("HumanoidRootPart")
	if not root then
		return self:notify(timing, "No humanoid root part found.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if character:GetAttribute("CurrentState") == "Attacking" or character:GetAttribute("CurrentState") == "Skill" then
		return self:notify(timing, "Currently attacking.")
	end

	if self:stopped(self.track, timing) then
		return false
	end

	local options = HitboxOptions.new(root, timing)
	options.spredict = true
	options.action = action
	options.entity = self.entity

	local info = RepeatInfo.new(timing)
	info.track = self.track

	if not self:hc(options, timing.duih and info or nil) then
		return self:notify(timing, "Not in hitbox.")
	end

	return true
end)

---Add a new Keyframe action.
---@param self AnimatorDefender
---@param action Action
---@param tp number
function AnimatorDefender:akeyframe(action, tp)
	-- Set time position.
	action.tp = tp

	-- Insert in list.
	table.insert(self.keyframes, action)
end

---Get time position of current track.
---@return number?
function AnimatorDefender:tp()
	if not self.track or self.offset == nil then
		return nil
	end

	---@note: Compensate for ping. Convert seconds to time position by adjusting for speed.
	--- Higher speed means it will delay earlier.
	--- Smaller speed means it will delay later.
	return self.track.TimePosition + ((self.offset + self.sdelay()) / self.track.Speed)
end

---Get latest keyframe action that we've exceeded.
---@return Action?
AnimatorDefender.latest = LPH_NO_VIRTUALIZE(function(self)
	local latestKeyframe = nil
	local latestTimePosition = nil

	for _, keyframe in next, self.keyframes do
		if (self:tp() or 0.0) <= keyframe.tp then
			continue
		end

		if latestTimePosition and keyframe.tp <= latestTimePosition then
			continue
		end

		latestTimePosition = keyframe.tp
		latestKeyframe = keyframe
	end

	return latestKeyframe
end)

---Update handling.
---@param self AnimatorDefender
AnimatorDefender.update = LPH_NO_VIRTUALIZE(function(self)
	for track, data in next, self.pbdata do
		-- Don't process tracks.
		if not Configuration.expectToggleValue("ShowAnimationVisualizer") then
			self.pbdata[track] = nil
			continue
		end

		-- Check if the track is playing.
		if not track.IsPlaying then
			-- Remove out of 'pbdata' and put it in to the recorded table.
			self.pbdata[track] = nil
			self.rpbdata[tostring(track.Animation.AnimationId)] = data

			-- Continue to next playback data.
			continue
		end

		-- Start tracking the animation's speed.
		data:astrack(track.Speed)
	end

	-- Run on validated track & timing.
	if not self.track or not self.timing then
		return
	end

	if not self.track.IsPlaying then
		return
	end

	-- Find the latest keyframe that we have exceeded, if there is even any.
	local latest = self:latest()
	if not latest then
		return
	end

	-- Clear the keyframes that we have exceeded.
	local tp = self:tp() or 0.0

	for idx, keyframe in next, self.keyframes do
		if tp <= keyframe.tp then
			continue
		end

		self.keyframes[idx] = nil
	end

	-- Log.
	self:notify(
		self.timing,
		"(%.2f) (really %.2f) Keyframe action type '%s' is being executed.",
		tp,
		self.track.TimePosition,
		latest._type
	)

	-- Ok, run action of this keyframe.
	self.maid:mark(
		TaskSpawner.spawn(
			string.format("KeyframeAction_%s", latest._type),
			self.handle,
			self,
			self.timing,
			latest,
			false
		)
	)
end)

---Virtualized processing checks.
---@param track AnimationTrack
---@return boolean
function AnimatorDefender:pvalidate(track)
	if track.Priority == Enum.AnimationPriority.Core then
		return false
	end

	return true
end

---Process animation track.
---@todo: AP telemetry - aswell as tracking effects that are added with timestamps and current ping to that list.
---@param self AnimatorDefender
---@param track AnimationTrack
AnimatorDefender.process = LPH_NO_VIRTUALIZE(function(self, track)
	if players.LocalPlayer.Character and self.entity == players.LocalPlayer.Character then
		return
	end

	if not self:pvalidate(track) then
		return
	end

	-- Clean up Keyframe maid.
	self.kfmaid:clean()

	-- Add to playback data list.
	if Configuration.expectToggleValue("ShowAnimationVisualizer") then
		self.pbdata[track] = PlaybackData.new(self.entity)
	end

	-- Animation ID.
	local aid = tostring(track.Animation.AnimationId)

	-- In logging range?
	local distance = self:distance(self.entity)
	local ilr = distance
		and (
			distance >= (Configuration.expectOptionValue("MinimumLoggerDistance") or 0)
			and distance <= (Configuration.expectOptionValue("MaximumLoggerDistance") or 0)
		)

	-- Keyframe logging.
	local keyframeReached = Signal.new(track.KeyframeReached)

	self.kfmaid:add(keyframeReached:connect("AnimationDefender_OnKeyFrameReached", function(kfname)
		if not ilr then
			return
		end

		if kfMemoryTable[kfname] then
			return
		end

		kfMemoryTable[kfname] = true

		Library:AddKeyFrameEntry(distance, aid, kfname, track.TimePosition, false)
	end))

	for kfname, _ in next, kfMemoryTable do
		local success, tp = pcall(function()
			return track:GetTimeOfKeyframe(kfname)
		end)

		if not success then
			continue
		end

		Library:AddKeyFrameEntry(distance, aid, kfname, tp, true)
	end

	---@type AnimationTiming?
	local timing = self:initial(self.entity, SaveManager.as, self.entity.Name, aid)
	if not timing then
		return
	end

	if ilr then
		Library:AddExistAnimEntry(self.entity.Name, distance, timing)
	end

	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Set current data.
	self.timing = timing
	self.track = track
	self.offset = self.rdelay()

	-- Use module over actions.
	if timing.umoa then
		return self:module(timing)
	end

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		return self:actions(timing)
	end

	-- Start RPUE.
	local info = RepeatInfo.new(timing, self.rdelay())
	info.track = track

	self:mark(Task.new(string.format("RPUE_%s_%i", timing.name, 0), function()
		return timing:rsd() - info.irdelay - self.sdelay()
	end, timing.punishable, timing.after, self.rpue, self, self.entity, timing, info))

	-- Notify.
	self:notify(
		timing,
		"Added RPUE '%s' (%.2fs, then every %.2fs) with ping '%.2f' (changing) subtracted.",
		PP_SCRAMBLE_STR(timing.name),
		timing:rsd(),
		timing:rpd(),
		self.rtt()
	)
end)

---Clean up the defender.
function AnimatorDefender:clean()
	-- Empty data.
	self.keyframes = {}
	self.heffects = {}

	-- Empty Keyframe maid.
	self.kfmaid:clean()

	-- Clean through base method.
	Defender.clean(self)
end

---Create new AnimatorDefender object.
---@param animator Animator
---@return AnimatorDefender
function AnimatorDefender.new(animator)
	local entity = animator:FindFirstAncestorWhichIsA("Model")
	if not entity then
		return error(string.format("AnimatorDefender.new(%s) - no entity.", animator:GetFullName()))
	end

	local self = setmetatable(Defender.new(), AnimatorDefender)
	local animationPlayed = Signal.new(animator.AnimationPlayed)

	self.animator = animator
	self.entity = entity
	self.kfmaid = Maid.new()

	self.track = nil
	self.timing = nil
	self.rdelay = nil

	self.heffects = {}
	self.keyframes = {}
	self.pbdata = {}
	self.rpbdata = {}

	self.maid:mark(animationPlayed:connect(
		"AnimatorDefender_OnAnimationPlayed",
		LPH_NO_VIRTUALIZE(function(track)
			self:process(track)
		end)
	))

	return self
end

-- Return AnimatorDefender module.
return AnimatorDefender
