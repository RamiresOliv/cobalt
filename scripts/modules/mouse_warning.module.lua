local w = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local runSEvent = nil
local lastWarn = nil
w.spawn = function(gui, t, time, offset, inverted)
	spawn(function()
		local cursorFrame = ReplicatedStorage.ui.mouse_warning:Clone()
		local currentBG = cursorFrame.bg
		cursorFrame.Position = UDim2.new(1000, 0, 0, 0)
		local m = Players.LocalPlayer:GetMouse()

		if lastWarn then lastWarn:Destroy() end
		lastWarn = cursorFrame
		cursorFrame.bg.txt.Text = t
		
		local invertedOffset = UDim2.new()
		runSEvent = RunService.RenderStepped:Connect(function()
			if not cursorFrame then 
				runSEvent:Disconnect()
				return
			end
			
			if inverted == true and currentBG then
				invertedOffset = UDim2.new(0,-currentBG.AbsoluteSize.X - 25,0,0)
			end
			
			cursorFrame.Position = UDim2.new(0, m.X, 0, m.Y) + invertedOffset - (offset or UDim2.new())
		end)
		
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
