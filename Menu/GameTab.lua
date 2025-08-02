-- GameTab module.
local GameTab = {}

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
end

---Debugging section.
---@param groupbox table
function GameTab.initDebuggingSection(groupbox)
	local irltSlider = nil

	local irlToggle = groupbox:AddToggle("IncomingReplicationLag", {
		Text = "Incoming Replication Lag",
		Default = false,
		Callback = function(value)
			if not irltSlider then
				return
			end

			settings().Network.IncomingReplicationLag = value and irltSlider.Value or 0
		end,
	})

	local irltDepBox = groupbox:AddDependencyBox()

	irltSlider = irltDepBox:AddSlider("IncomingReplicationLagTime", {
		Text = "Incoming Replication Lag Time",
		Default = 0.1,
		Min = 0,
		Max = 5,
		Suffix = "s",
		Rounding = 2,
		Callback = function(value)
			settings().Network.IncomingReplicationLag = value
		end,
	})

	irltDepBox:SetupDependencies({
		{ irlToggle, true },
	})

	groupbox:AddToggle("ShowDebugInformation", {
		Text = "Show Debug Information",
		Default = false,
	})

	groupbox:AddToggle("StopGameLogging", {
		Text = "Stop Game Logging",
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
