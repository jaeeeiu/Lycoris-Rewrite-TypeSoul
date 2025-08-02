-- Hooking related stuff is handled here.
local Hooking = {}

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Old hooked functions.
local oldPrint = nil
local oldWarn = nil

---On print.
---@return any
local onPrint = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldPrint(...)
	end

	if Configuration.expectToggleValue("StopGameLogging") then
		return
	end

	return oldPrint(...)
end)

---On warn.
---@return any
local onWarn = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldWarn(...)
	end

	if Configuration.expectToggleValue("StopGameLogging") then
		return
	end

	return oldWarn(...)
end)

---Hooking initialization.
function Hooking.init()
	oldWarn = hookfunction(warn, onWarn)
	oldPrint = hookfunction(print, onPrint)

	Logger.warn("Client-side anticheat has been penetrated.")
end

---Hooking detach.
function Hooking.detach()
	if oldPrint then
		hookfunction(print, oldPrint)
	end

	if oldWarn then
		hookfunction(warn, oldWarn)
	end

	Logger.warn("Pulled out of client-side anticheat.")
end

-- Return Hooking module.
return Hooking
