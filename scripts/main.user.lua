local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local uiI = ReplicatedStorage:WaitForChild("ui")
local global = ReplicatedStorage:WaitForChild("global")
local values = global:WaitForChild("values")
local gui = StarterGui.viewframe:Clone()

local buttonsObjs = {}
local buttonsState = {}
local buttonsDatas = {}

local firstModule = {}

local OS = ReplicatedStorage.root
values.cd.Value = OS.home
limiteCD = OS

n = 0
local modules = script.pages:GetChildren()
table.sort(modules, function(a, b)
	-- Extrai os números do começo dos nomes
	local num_a = tonumber(a.Name:match("^(%d+)"))
	local num_b = tonumber(b.Name:match("^(%d+)"))
	return num_a < num_b
end)

for i, v in ipairs(modules) do
	if v:IsA("ModuleScript") then
		n += 1
		local module = require(v)
		
		local button = gui.bg.left.list.templates.b:Clone()
		button.Parent = gui.bg.left.list;
		button.content.Text = module.settings.name;
		button.BackgroundColor3 = Color3.new(0.14902, 0.14902, 0.164706)
		button.content.TextColor3 = Color3.new(0.682353, 0.752941, 0.784314)
		button.Visible = true
		buttonsObjs[module.settings.name] = button
		buttonsState[module.settings.name] = false
		
		button.MouseEnter:Connect(function()
			if buttonsState[module.settings.name] ~= false then return; end
			button.BackgroundColor3 = Color3.new(1, 1, 1)
			button.content.TextColor3 = Color3.new(0, 0, 0)
		end)
		button.MouseLeave:Connect(function()
			if buttonsState[module.settings.name] ~= false then return; end
			button.BackgroundColor3 = Color3.new(0.14902, 0.14902, 0.164706)
			button.content.TextColor3 = Color3.new(0.682353, 0.752941, 0.784314)
		end)
		
		local ui = nil
		if module.settings.page_obj_name and uiI:WaitForChild("pages"):FindFirstChild(module.settings.page_obj_name) then
			local pre_ui = uiI:WaitForChild("pages"):FindFirstChild(module.settings.page_obj_name):Clone()
			pre_ui.Parent = gui.bg.content
			ui = pre_ui
		else
			local pre_ui = uiI:WaitForChild("pages"):FindFirstChild("core_empty_page"):Clone()
			pre_ui.Parent = gui.bg.content
			ui = pre_ui
		end
		
		local enable, disable = module.init(ui, button)
		buttonsDatas[module.settings.name] = {
			ui = ui,
			enable = enable,
			disable = disable,
			name = module.settings.name,
			objName = module.settings.page_obj_name
		}
		
		button.content.MouseButton1Click:Connect(function()
			if buttonsState[module.settings.name] == false then
				buttonsState[module.settings.name] = true
				button.BackgroundColor3 = Color3.new(0.294118, 0.513725, 0.972549)
				button.content.TextColor3 = Color3.new(0.105882, 0.164706, 0.290196)
				for i, v in buttonsObjs do
					if i ~= module.settings.name then
						buttonsDatas[i].disable(buttonsObjs[i], buttonsDatas[i].ui, buttonsState[i]) -- yeahhhh
						buttonsState[i] = false
						v.BackgroundColor3 = Color3.new(0.14902, 0.14902, 0.164706)
						v.content.TextColor3 = Color3.new(0.682353, 0.752941, 0.784314)
					end
				end
				enable(button, ui, buttonsState[module.settings.name])
				gui.bg["1_header"].left["2_title"].Text = (buttonsDatas[module.settings.name]["objName"] or "unknown_page")
			end
		end)

		if n == 1 then
			firstModule = {
				name = module.settings.name,
				objName = module.settings.page_obj_name,
				buttonObj = buttonsObjs[module.settings.name],
				buttonState = buttonsState[module.settings.name],
				buttonDatas = buttonsDatas[module.settings.name],
			}
		end
	end
end

if firstModule then
	buttonsState[firstModule.name] = true
	firstModule.buttonObj.BackgroundColor3 = Color3.new(0.294118, 0.513725, 0.972549)
	firstModule.buttonObj.content.TextColor3 = Color3.new(0.105882, 0.164706, 0.290196)
	firstModule.buttonDatas.enable(firstModule.buttonObj, firstModule.buttonDatas.ui, firstModule.buttonState)
	gui.bg["1_header"].left["2_title"].Text = firstModule.objName
end

local game_data = require(ReplicatedStorage.modules.game)

gui.bg.left.note.Text = "ui - v" .. game_data.version
gui.bg.left.note2.Text = game_data.versionName

if player.PlayerGui:FindFirstChild("viewframe") then
	player.PlayerGui.viewframe:Destroy()
end
gui.Parent = player.PlayerGui
gui.bg.Visible = true