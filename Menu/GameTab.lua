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
	GameTab.initLocalCharacterSection(tab:AddDynamicGroupbox("Local Character"))
end

-- Return GameTab module.
return GameTab
