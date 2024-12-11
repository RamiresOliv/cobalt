local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local global = ReplicatedStorage:WaitForChild("global")
local gui = StarterGui.loading:Clone()

local toload = {}

stoploop = false

spawn(function()
	repeat
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		wait(.1)
	until true == true
end)

spawn(function()
	while not stoploop do
		if stoploop then break end
		gui.lg.title.Text = "Cobalt is loading."
		wait(.3)
		if stoploop then break end
		gui.lg.title.Text = "Cobalt is loading.."
		wait(.3)
		if stoploop then break end
		gui.lg.title.Text = "Cobalt is loading..."
		wait(.3)
		if stoploop then break end
		gui.lg.title.Text = "Cobalt is loading"
		wait(.3)
	end
end)

if not RunService:IsStudio() then
	gui.lg.Visible = true
	gui.lg.line.filler.Size = UDim2.new(0,0,1,0)
	gui.Parent = player.PlayerGui
	script.Parent.main.Enabled = false

	for i, v in pairs(workspace:GetDescendants()) do table.insert(toload,v) end
	for i, v in pairs(game:GetService('ReplicatedStorage'):GetDescendants()) do table.insert(toload,v) end
	for i, v in pairs(game:GetService('StarterGui'):GetDescendants()) do table.insert(toload,v) end
	for i, v in pairs(game:GetService('SoundService'):GetDescendants()) do table.insert(toload,v) end

	for i, v in toload do
		local size = i/#toload
		ContentProvider:PreloadAsync({v})
		gui.lg.line.filler.Size = UDim2.new(size,0,1,0)
		gui.lg.total.Text = tostring(math.round((i / #toload) * 100)) .. "%"
	end
	
	stoploop = true
	gui.lg.title.Text = "Cobalt is loaded."
	wait(1)
	for i, v in pairs(gui.lg:GetChildren()) do
		if v.Name == "line" then
			TweenService:Create(v, TweenInfo.new(.5, Enum.EasingStyle.Linear), {
				BackgroundTransparency = 1
			}):Play()
			TweenService:Create(v.filler, TweenInfo.new(.5, Enum.EasingStyle.Linear), {
				BackgroundTransparency = 1
			}):Play()
		elseif v.Name ~= "header" then
			TweenService:Create(v, TweenInfo.new(.5, Enum.EasingStyle.Linear), {
				TextTransparency = 1
			}):Play()
		end
	end
	wait(.3)
	script.Parent.main.Enabled = true
	TweenService:Create(gui.lg, TweenInfo.new(.3, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1
	}):Play()
	TweenService:Create(gui.lg.header, TweenInfo.new(.3, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1
	}):Play()
	wait(.3)
	gui.lg.Visible = false
else
	stoploop = true
	gui.lg.Visible = false
end
