local a = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local modules = { console = require(ReplicatedStorage.modules.console)}

a.settings = {
	name = "Compiler Console",
	page_obj_name = "compiler_console",
}

function enable(button_frame, ui, state)
	for i, v in pairs(ui:GetChildren()) do
		if v:IsA("GuiBase") then
			v.Visible = true
		end
	end
end
function disable(button_frame, ui, state)
	for i, v in pairs(ui:GetChildren()) do
		if v:IsA("GuiBase") then
			v.Visible = false
		end
	end
end

local function worker(ui, console, button_frame)
	console:newInput("Write here!")
	console.inputEvent:Once(function(content: string)
		local text = ui.input.Text
		if text == "draw_cobalt" then
			console:write(console:color([[
      ___           ___           ___           ___           ___       ___     
     /\  \         /\  \         /\  \         /\  \         /\__\     /\  \    
    /::\  \       /::\  \       /::\  \       /::\  \       /:/  /     \:\  \   
   /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/  /       \:\  \  
  /:/  \:\  \   /:/  \:\  \   /::\~\:\__\   /::\~\:\  \   /:/  /        /::\  \ 
 /:/__/ \:\__\ /:/__/ \:\__\ /:/\:\ \:|__| /:/\:\ \:\__\ /:/__/        /:/\:\__\
 \:\  \  \/__/ \:\  \ /:/  / \:\~\:\/:/  / \/__\:\/:/  / \:\  \       /:/  \/__/
  \:\  \        \:\  /:/  /   \:\ \::/  /       \::/  /   \:\  \     /:/  /     
   \:\  \        \:\/:/  /     \:\/:/  /        /:/  /     \:\  \    \/__/      
    \:\__\        \::/  /       \::/__/        /:/  /       \:\__\              
     \/__/         \/__/         ~~            \/__/         \/__/              ]], "highlight"), nil, nil, true)
			worker(ui, console, button_frame)
			console:inputFocus()
			return;
		end
		console:write(text, "muted")
		ui.input.TextEditable = false
		ui.input.AutomaticSize = Enum.AutomaticSize.X
		ui.input.TextColor3 = Color3.new(0.223529, 0.223529, 0.223529)
		local b_text = button_frame.content.Text
		button_frame.content.Text = "[r] " .. b_text
		local success, r = pcall(function()
			return require(ReplicatedStorage.cobalt.cobalt)(content, console)
		end)
		if not success then
			console:write("[console-core]: cobalt had a fatal failure :/", "red")
		else
			if r[1] == false then
				console:write(r[2], "red")
			end
		end
		button_frame.content.Text = b_text
		ui.input.AutomaticSize = Enum.AutomaticSize.Y
		ui.input.TextColor3 = Color3.new(0.631373, 0.631373, 0.631373)
		ui.input.TextEditable = true
		worker(ui, console, button_frame)
		console:inputFocus()
	end)
end

a.init = function(ui, button_frame)
	local console = modules.console.init(player, ui:WaitForChild("templates"), ui:WaitForChild("logs"))

	local language = require(ReplicatedStorage.cobalt.language)
	console:write(console:color(`{language.name} {language.version} (language version & compiler version)`, "highlight"))
	console:write(console:color("Type your code below and press enter to run it", "highlight"))
	console:write(console:color("This page will compile and run the code you wish", "highlight"))
	console:write(console:color("This UI is under development, expect issues", "highlight"))
	
	for i, v: Instance in pairs(ui:GetChildren()) do
		if v:IsA("GuiBase") then
			v.Visible = false
		end
	end
	
	worker(ui, console, button_frame)
	
	return enable, disable;
end

return a
