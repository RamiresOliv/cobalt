local w = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local runSEvent = nil
local lastWarn = nil
w.spawn = function(gui, t, time, offset)
	spawn(function()
		local cursorFrame = ReplicatedStorage.ui.mouse_warning:Clone()
		cursorFrame.Position = UDim2.new(1000, 0, 0, 0)
		local m = Players.LocalPlayer:GetMouse()
		runSEvent = RunService.RenderStepped:Connect(function()
			if not cursorFrame then runSEvent:Disconnect() else cursorFrame.Position = UDim2.new(0, m.X, 0, m.Y) - (offset or UDim2.new()) end
		end)

		if lastWarn then lastWarn:Destroy() end
		lastWarn = cursorFrame
		cursorFrame.bg.txt.Text = t

		TweenService:Create(cursorFrame.bg, TweenInfo.new(.3), {
			BackgroundTransparency = 0.7
		}):Play()
		TweenService:Create(cursorFrame.bg.txt, TweenInfo.new(.3), {
			TextTransparency = 0
		}):Play()
		
		cursorFrame.Parent = gui
		wait(time or 5)
		pcall(function()
			local a = TweenService:Create(cursorFrame.bg, TweenInfo.new(.3), {
				BackgroundTransparency = 1
			})
			TweenService:Create(cursorFrame.bg.txt, TweenInfo.new(.3), {
				TextTransparency = 1
			}):Play()
			a:Play()
			a.Completed:Connect(function()
				cursorFrame:Destroy()
			end)
		end)
	end)

	return true
end

return w
