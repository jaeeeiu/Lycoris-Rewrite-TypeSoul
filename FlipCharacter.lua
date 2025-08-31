local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

local RunService = game:GetService("RunService")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

RunService.Heartbeat:Connect(function()
	local currentCFrame = humanoidRootPart.CFrame
	humanoidRootPart.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(math.rad(180), 0, 0)
end)
