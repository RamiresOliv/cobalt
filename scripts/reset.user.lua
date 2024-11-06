local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local global = ReplicatedStorage:WaitForChild("global")
local gui = StarterGui.restart:Clone()

local mouse_warning = require(script.Parent.modules.mouse_warning)

local restarting = false

gui.rt.options.yes.context.MouseEnter:Connect(function()
	gui.rt.options.yes.BorderSizePixel = 2
end)
gui.rt.options.yes.context.MouseLeave:Connect(function()
	gui.rt.options.yes.BorderSizePixel = 0
end)

function doBefore()
	if not restarting then
		doit()
	else
		mouse_warning.spawn(gui, "delay active")
	end
end

gui.rt.options.yes.context.MouseButton1Click:Connect(function()
	gui.rt.Visible = false
	doBefore()
end)

spawn(function()
	local bindable = Instance.new("BindableEvent")
	bindable.Event:Connect(doBefore)
	repeat
		pcall(function()
			StarterGui:SetCore("ResetButtonCallback", bindable)
		end)
		wait(.1)
	until true == true
end)


gui.rt.options.no.context.MouseEnter:Connect(function()
	gui.rt.options.no.BorderSizePixel = 2
end)
gui.rt.options.no.context.MouseLeave:Connect(function()
	gui.rt.options.no.BorderSizePixel = 0
end)
gui.rt.options.no.context.MouseButton1Click:Connect(function()
	gui.rt.Visible = false
end)

LControlKeyDown = false
UserInputService.InputBegan:Connect(function(input, gpe)
	
	if input.KeyCode == Enum.KeyCode.R then
		if LControlKeyDown then
			if not gui.rt.Visible then
				doBefore()-- Direct restart then
			end
		elseif not gpe then
			gui.rt.Visible = not gui.rt.Visible
		end
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		LControlKeyDown = true
	end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.LeftControl then
		LControlKeyDown = false
	end
end)

function doit()
	mouse_warning.spawn(gui, "restarting cobalt...")
	restarting = true
	wait(.4)
	script.Parent.main.Enabled = false
	for i, v in pairs(ReplicatedStorage.temporary.functions:GetChildren()) do
		v:Destroy()
	end
	for i, v in pairs(ReplicatedStorage.temporary.values:GetChildren()) do
		v:Destroy()
	end
	mouse_warning.spawn(gui, "cobalt halted")
	wait(1)
	script.Parent.main.Enabled = true
	mouse_warning.spawn(gui, [[cobalt halted
cobalt started]])
	wait(5)
	restarting = false
	return "done"
end

gui.rt.Visible = false
gui.Parent = player.PlayerGui