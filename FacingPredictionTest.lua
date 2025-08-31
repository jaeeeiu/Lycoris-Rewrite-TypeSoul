local previous = nil

game:GetService("RunService").RenderStepped:Connect(function(dt)
	local lv = game:GetService("Workspace").lIlIlIIlIlIlllllIlI.HumanoidRootPart.CFrame.LookVector
	if lv.Magnitude <= 0.0001 then
		return
	end

	if previous then
		local hlv = (lv.X - previous) / dt
		if hlv > 0 then
			print(hlv)
		end
	end

	previous = lv.X
end)
