local a = {}

a.settings = {
	name = "Code Editor",
	page_obj_name = "code_editor",
}

function updateLineCounts(ui)
	local _, num = ui.Editor.TextBox.Text:gsub("\n", "")

	for i, v in pairs(ui.Editor.list:GetChildren()) do
		if v:IsA("TextLabel") then
			v:Destroy()
		end
	end
	for i = 1, (num + 1) do
		local lineCount = ui.Editor.list.template.lc:Clone()
		lineCount.Parent = ui.Editor.list
		lineCount.Text = tostring(i)
		lineCount.Visible = true
	end
end

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


a.init = function(ui, onClick)
	for i, v in pairs(ui:GetChildren()) do
		v.Visible = false
	end
	
	ui.Editor.TextBox.Text = require(script.codes)[math.random(1, #require(script.codes))]
	
	ui.Editor.TextBox.Focused:Once(function()
		ui.Editor.TextBox.SelectionStart = 1
		ui.Editor.TextBox.CursorPosition = ui.Editor.TextBox.Text:len() + 1
	end)
	
	updateLineCounts(ui)
	ui.Editor.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateLineCounts(ui)
	end)
	
	local firstTime = false
	ui.b.content.MouseButton1Click:Connect(function()
		if not firstTime then
			firstTime = true
			ui.Editor.TextBox.Text = ui.Editor.TextBox.Text .. "\nNot working! :l"
		else
			ui.Editor.TextBox.Text = ui.Editor.TextBox.Text .. "\nStill not working... :l"
		end
	end)
	return enable, disable;
end

return a
