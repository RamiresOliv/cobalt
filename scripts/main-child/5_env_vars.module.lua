local a = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local modules = { console = require(ReplicatedStorage.modules.console)}

function enable(button, ui, state)
	for i, v in pairs(ui:GetChildren()) do
		v.Visible = true
	end
end
function disable(button, ui, state)
	for i, v in pairs(ui:GetChildren()) do
		v.Visible = false
	end
end

a.settings = {
	name = "Env. Vars",
}

a.init = function(ui, onClick)
	for i, v in pairs(ui:GetChildren()) do
		v.Visible = false
	end
	
	return enable, disable, nil;
end

return a