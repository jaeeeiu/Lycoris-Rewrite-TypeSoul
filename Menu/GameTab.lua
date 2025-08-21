-- GameTab module.
local GameTab = {}

-- Services.
local players = game:GetService("Players")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---Initialize local character section.
---@param groupbox table
function GameTab.initLocalCharacterSection(groupbox)
	local speedHackToggle = groupbox:AddToggle("Speedhack", {
		Text = "Speedhack",
		Tooltip = "Modify your character's velocity while moving.",
		Default = false,
	})

	speedHackToggle:AddKeyPicker("SpeedhackKeybind", { Default = "N/A", SyncToggleState = true, Text = "Speedhack" })

	local speedDepBox = groupbox:AddDependencyBox()

	speedDepBox:AddSlider("SpeedhackSpeed", {
		Text = "Speedhack Speed",
		Default = 200,
		Min = 0,
		Max = 300,
		Suffix = "/s",
		Rounding = 0,
	})

	local flyToggle = groupbox:AddToggle("Fly", {
		Text = "Fly",
		Tooltip = "Set your character's velocity while moving to imitate flying.",
		Default = false,
	})

	flyToggle:AddKeyPicker("FlyKeybind", { Default = "N/A", SyncToggleState = true, Text = "Fly" })

	local flyDepBox = groupbox:AddDependencyBox()

	flyDepBox:AddSlider("FlySpeed", {
		Text = "Fly Speed",
		Default = 200,
		Min = 0,
		Max = 450,
		Suffix = "/s",
		Rounding = 0,
	})

	flyDepBox:AddSlider("FlyUpSpeed", {
		Text = "Spacebar Fly Speed",
		Default = 150,
		Min = 0,
		Max = 300,
		Suffix = "/s",
		Rounding = 0,
	})

	local noclipToggle = groupbox:AddToggle("NoClip", {
		Text = "NoClip",
		Tooltip = "Disable collision(s) for your character.",
		Default = false,
	})

	noclipToggle:AddKeyPicker("NoClipKeybind", { Default = "N/A", SyncToggleState = true, Text = "NoClip" })

	local infJumpToggle = groupbox:AddToggle("InfiniteJump", {
		Text = "Infinite Jump",
		Tooltip = "Boost your velocity while the jump key is held.",
		Default = false,
	})

	infJumpToggle:AddKeyPicker(
		"InfiniteJumpKeybind",
		{ Default = "N/A", SyncToggleState = true, Text = "Infinite Jump" }
	)

	local infiniteJumpDepBox = groupbox:AddDependencyBox()

	infiniteJumpDepBox:AddSlider("InfiniteJumpBoost", {
		Text = "Infinite Jump Boost",
		Default = 50,
		Min = 0,
		Max = 500,
		Suffix = "/s",
		Rounding = 0,
	})

	local atbToggle = groupbox:AddToggle("AttachToBack", {
		Text = "Attach To Back",
		Tooltip = "Start following the nearest entity based on a distance and height offset.",
		Default = false,
	})

	atbToggle:AddKeyPicker("AttachToBackKeybind", { Default = "N/A", SyncToggleState = true, Text = "Attach To Back" })

	local atbDepBox = groupbox:AddDependencyBox()

	atbDepBox:AddSlider("BackOffset", {
		Text = "Distance To Entity",
		Default = 5,
		Min = -30,
		Max = 30,
		Suffix = "studs",
		Rounding = 0,
	})

	atbDepBox:AddSlider("HeightOffset", {
		Text = "Height Offset",
		Default = 0,
		Min = -30,
		Max = 30,
		Suffix = "studs",
		Rounding = 0,
	})

	atbDepBox:SetupDependencies({
		{ Toggles.AttachToBack, true },
	})

	infiniteJumpDepBox:SetupDependencies({
		{ Toggles.InfiniteJump, true },
	})

	speedDepBox:SetupDependencies({
		{ Toggles.Speedhack, true },
	})

	flyDepBox:SetupDependencies({
		{ Toggles.Fly, true },
	})

	groupbox:AddButton("Redeem Codes", function()
		local codes = {
			"jambajuice1v1",
			"butisitenough",
			"codecodecode",
			"codelolhaha",
			"codeofdoom",
			"600MVisits",
			"300KLikes",
			"serverlistfixed",
			"thosewhoknowemblem",
			"superduperfunsecretcode",
			"wowshutdowncodeyeah",
			"yesterdayshutdown",
			"thanksfor900k",
			"setrona1vertagzeu0",
			"excaliburfool",
			"higuyscode",
			"thisiswhywetestthosewhoknow",
			"goplayranked",
			"somebugsfixes",
			"800kcodeyeah",
			"thanksforpatience",
			"raidsfixed",
			"compensationforinconvenientrelease",
			"sorryforthebankbugs",
			"mythoughtsonthislater",
			"3daysthosewhoknow",
			"rerererelease",
			"privateservercompensation",
			"promiseddecembercode",
			"codeforshutdownisuppose",
		}

		local localPlayer = players.LocalPlayer
		local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
		local characterHandler = character:WaitForChild("CharacterHandler")
		local remotes = characterHandler:WaitForChild("Remotes")
		local codesRemote = remotes:WaitForChild("Codes")

		for _, code in next, codes do
			local success, result = nil, nil

			repeat
				-- Invoke.
				success, result = codesRemote:InvokeServer(code)

				-- Wait.
				task.wait(0.5)
			until result ~= nil

			Logger.notify(
				"(%s, %s) Code '%s' has been attempted to be redeemed.",
				tostring(success),
				tostring(result),
				code
			)
		end
	end)
end

---Initialize player monitoring section.
---@param groupbox table
function GameTab.initPlayerMonitoringSection(groupbox)
	groupbox:AddToggle("ShowRobloxChat", {
		Text = "Show Roblox Chat",
		Default = true,
	})

	groupbox:AddToggle("ShowOwnership", {
		Text = "Show Network Ownership",
		Default = false,
	})

	groupbox:AddToggle("PlayerProximity", {
		Text = "Player Proximity Notifications",
		Tooltip = "When other players are within specified distance, notify the user.",
		Default = false,
	})

	local ppDepBox = groupbox:AddDependencyBox()

	ppDepBox:AddSlider("PlayerProximityRange", {
		Text = "Player Proximity Distance",
		Default = 1000,
		Min = 50,
		Max = 2500,
		Suffix = "studs",
		Rounding = 0,
	})

	ppDepBox:AddToggle("PlayerProximityBeep", {
		Text = "Play Beep Sound",
		Tooltip = "Use a beep sound along with the proximity notification.",
		Default = false,
	})

	local ppbDepBox = ppDepBox:AddDependencyBox()

	ppbDepBox:AddSlider("PlayerProximityBeepVolume", {
		Text = "Beep Sound Volume",
		Default = 0.1,
		Min = 0,
		Max = 10,
		Suffix = "v",
		Rounding = 2,
	})

	ppbDepBox:SetupDependencies({
		{ Toggles.PlayerProximityBeep, true },
	})

	ppDepBox:SetupDependencies({
		{ Toggles.PlayerProximity, true },
	})
end

---Debugging section.
---@param groupbox table
function GameTab.initDebuggingSection(groupbox)
	groupbox:AddToggle("ShowDebugInformation", {
		Text = "Show Debug Information",
		Default = false,
	})
end

---Initialize tab.
function GameTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Game")

	-- Initialize sections.
	GameTab.initDebuggingSection(tab:AddDynamicGroupbox("Debugging"))
	GameTab.initPlayerMonitoringSection(tab:AddDynamicGroupbox("Player Monitoring"))
	GameTab.initLocalCharacterSection(tab:AddDynamicGroupbox("Local Character"))
end

-- Return GameTab module.
return GameTab
