local a = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local modules = { console = require(ReplicatedStorage.modules.console)}

a.settings = {
	name = "Functions List",
	page_obj_name = "functions_list",
}

function enable(button, ui, state)
	for i, v in pairs(ui:GetChildren()) do
		if v:IsA("GuiBase") then
			v.Visible = true
		end
	end
end
function disable(button, ui, state)
	for i, v in pairs(ui:GetChildren()) do
		if v:IsA("GuiBase") then
			v.Visible = false
		end
	end
end

function load(ui)
	local cobalt_types = require(ReplicatedStorage.cobalt.types)
	for name, data in cobalt_types.mapping do
		local f = ui.templates.gaming_frame:Clone()
		f.Name = name;
		
		local paramsText;
		if #data.params > 0 then
			paramsText = "(" .. tostring(name) .. " "
			local paramsTexted = ""

			for i, v in pairs(data.params) do
				if i == #data.params then
					if i > data.requiredEntries then
						paramsTexted = paramsTexted .. "<" .. v .. ">"
					else
						paramsTexted = paramsTexted .. "[" .. v .. "]"
					end
				else
					if i > data.requiredEntries then
						paramsTexted = paramsTexted .. "<" .. v .. "> "
					else
						paramsTexted = paramsTexted .. "[" .. v .. "] "
					end
				end
			end
			paramsText = paramsText .. paramsTexted
		else
			paramsText = "(" .. tostring(name)
		end

		if data.openEntries == true then
			paramsText = paramsText .. " ...): "
		else
			paramsText = paramsText .. "): "
		end
		paramsText = paramsText .. tostring(data.returns)
		
		f["1_title"].Text = paramsText;
		f["2_desc"].Text = data.description;
		f.Parent = ui.list;
		f.Visible = true;
	end
end

a.init = function(ui, onClick)
	for i, v: Instance in pairs(ui:GetChildren()) do
		if v:IsA("GuiBase") then
			v.Visible = false
		end
	end
	
	load(ui)
	
	ui.searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local text: string = ui.searchInput.Text
		
		text = text:gsub(" ", "")
		
		if #text > 0 then
			for i, v: Instance in pairs(ui.list:GetChildren()) do
				if not v:IsA("Frame") then continue end
				if v.Name:sub(1, #text):lower() == text:lower() then
					v.Visible = true
				else
					v.Visible = false
				end
			end
		else
			for i, v: Instance in pairs(ui.list:GetChildren()) do
				if v:IsA("Frame") then
					v.Visible = true
				end
			end
		end
	end)
	
	return enable, disable;
end

return a
	
	--[[
	
function loadPage(p, name, template)
	local pageB = tmptsdc.navigation_frame.page:Clone()
	pageB.Parent = p
	
	local isChar = false
	local chars = {
		"a","b","c","d","e","f","g","h","i","j",
		"k","l","m","n","o","p","q","r","s","t",
		"u","v","w","x","y","z"
	}
	
	for i, v in chars do
		if string.lower(string.sub(name, 1, 1)) == v then
			isChar = true
			break
		end
	end
	
	if isChar then
		pageB.Name = name
	else
		pageB.Name = "o"
	end
	pageB.action.Text = tostring(name)
	pageB.action.MouseEnter:Connect(function()
		if pageB.open.Value == false then
			pageB.BackgroundTransparency = 0
			pageB.action.TextColor3 = Color3.new(0, 0, 0)
			TweenService:Create(pageB.action, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0, 5, 0, 0)
			}):Play()
		end
	end)
	pageB.action.MouseLeave:Connect(function()
		if pageB.open.Value == false then
			pageB.BackgroundTransparency = 1
			pageB.action.TextColor3 = Color3.new(1, 1, 1)
			TweenService:Create(pageB.action, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		end
	end)

	pageB.action.MouseButton1Click:Connect(function()
		for P_i, P_v in pairs(gui.dc.navigation:GetChildren()) do
			for i, v in pairs(P_v:GetChildren()) do
				if v:IsA("Frame") then
					v.open.Value = false
					v.BackgroundTransparency = 1
					v.action.TextColor3 = Color3.new(1, 1, 1)

					TweenService:Create(v.action, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
						Position = UDim2.new(0, 0, 0, 0)
					}):Play()
				end
			end
		end

		pageB.open.Value = true
		pageB.BackgroundTransparency = 0
		pageB.action.TextColor3 = Color3.new(0, 0, 0)
		gui.dc.GS.Visible = false
		gui.dc.page.Visible = true
		gui.dc.nav_interactions.help.open.Value = false
		TweenService:Create(gui.dc.nav_interactions.help.context, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			TextColor3 = Color3.new(1, 1, 1)
		}):Play()
		TweenService:Create(gui.dc.nav_interactions.help.bg, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			BackgroundColor3 = Color3.new(1, 0.466667, 0.027451),
			Rotation = 0
		}):Play()

		TweenService:Create(pageB.action, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0, 10, 0, 0)
		}):Play()

		for i, v in pairs(gui.dc.page:GetChildren()) do
			if not v:IsA("UIBase") then
				v:Destroy()
			end
		end
		for i, v in pairs(template:GetChildren()) do
			local item = v:Clone()
			item.Parent = gui.dc.page
			item.Visible = true
		end
	end)
end
	]]