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

running = false
local connection = nil
local function worker(ui, console, button_frame)
	local input = ui:WaitForChild("2_input")
	
	console:newInput("Write here!")
	connection = console.inputEvent:Once(function(content: string)
		if running then return end
		local text = input.Text
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
		input.TextEditable = false
		input.AutomaticSize = Enum.AutomaticSize.X
		input.TextColor3 = Color3.new(0.223529, 0.223529, 0.223529)
		local b_text = button_frame.content.Text
		button_frame.content.Text = "[r] " .. b_text
		running = true
		local success, r = pcall(function()
			return require(ReplicatedStorage.cobalt.cobalt)(content, console)
		end)
		if not success then
			r = r:gsub("ReplicatedStorage.", "RS.")
			console:write("[console-core:roblox-native:handled]: cobalt execution had a fatal failure :/", "red")
			console:write("[console-core:roblox-native:handled:DATA]: " .. r, "yellow")
			console:write("[!]: you may report this issue.", "muted")
			warn("cobalt failed PCALL ISSUE: " .. r)
		else
			if r[1] == false then
				if r[3] == true then
					r[2] = r[2]:gsub("ReplicatedStorage.", "RS.")
					console:write("[cobalt-core:handled]: high level error happened :/", "red")
					console:write("[cobalt-core:handled:DATA]: " .. r[2], "yellow")
					console:write("[!]: you may report this issue.", "muted")
				else
					console:write(r[2], "red")
				end
			end
		end
		running = false
		button_frame.content.Text = b_text
		input.AutomaticSize = Enum.AutomaticSize.Y
		input.TextColor3 = Color3.new(0.631373, 0.631373, 0.631373)
		input.TextEditable = true
		worker(ui, console, button_frame)
		console:inputFocus()
	end)
end

a.init = function(ui, button_frame)
	local console = modules.console.init(player, ui:WaitForChild("templates"), ui:WaitForChild("1_logs"))
	local input = ui:WaitForChild("2_input")

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
	
	ReplicatedStorage.global.values.user_name.Value = tostring(player.DisplayName) or "usr"
	ReplicatedStorage.global.values.pc_name.Value = "desktop-" .. tostring(player.UserId) or "desktop-unknown"
	
	running = false
	worker(ui, console, button_frame)
	return enable, disable, function(self, text)
		if running then return false end
		
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
		input.TextEditable = false
		input.AutomaticSize = Enum.AutomaticSize.X
		input.TextColor3 = Color3.new(0.223529, 0.223529, 0.223529)
		local b_text = button_frame.content.Text
		button_frame.content.Text = "[r] " .. b_text
		running = true
		local success, r = pcall(function()
			return require(ReplicatedStorage.cobalt.cobalt)(text, console)
		end)
		if not success then
			r = r:gsub("ReplicatedStorage.", "RS.")
			console:write("[console-core:roblox-native:handled]: cobalt execution had a fatal failure :/", "red")
			console:write("[console-core:roblox-native:handled:DATA]: " .. r, "yellow")
			console:write("[!]: you may report this issue.", "muted")
			warn("cobalt failed PCALL ISSUE: " .. r)
		else
			if r[1] == false then
				if r[3] == true then
					r[2] = r[2]:gsub("ReplicatedStorage.", "RS.")
					console:write("[cobalt-core:handled]: high level error happened :/", "red")
					console:write("[cobalt-core:handled:DATA]: " .. r[2], "yellow")
					console:write("[!]: you may report this issue.", "muted")
				else
					console:write(r[2], "red")
				end
			end
		end
		button_frame.content.Text = b_text
		input.AutomaticSize = Enum.AutomaticSize.Y
		input.TextColor3 = Color3.new(0.631373, 0.631373, 0.631373)
		input.TextEditable = true
		running = false
		if not connection or connection.Connected ~= true then
			--warn("not connected, so doing.")
			worker(ui, console, button_frame)
		--[[else
			warn("connected, so ignoring.")]]
		end
		return true;
	end;
end

return a
