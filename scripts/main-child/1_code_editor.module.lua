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


a.init = function(ui, onClick, popup, getPageData)
	for i, v in pairs(ui:GetChildren()) do
		v.Visible = false
	end
	
	ui.Editor.TextBox.Text = "; here you can write your code before send it to the console.\n; press 'run code' to run in console.\n\n" .. require(script.codes)[math.random(1, #require(script.codes))]
	
	ui.Editor.TextBox.Focused:Once(function()
		ui.Editor.TextBox.SelectionStart = 1
		ui.Editor.TextBox.CursorPosition = ui.Editor.TextBox.Text:len() + 1
	end)
	
	updateLineCounts(ui)
	ui.Editor.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateLineCounts(ui)
	end)
	
	ui.b.content.MouseEnter:Connect(function()
		ui.b.BackgroundColor3 = Color3.new(1, 1, 1)
		ui.b.content.TextColor3 = Color3.new(0, 0, 0)
		popup("this will run the code in the console.", 2, UDim2.new(0,0,0,0), true)
	end)
	ui.b.content.MouseLeave:Connect(function()
		ui.b.BackgroundColor3 = Color3.new(0.14902, 0.14902, 0.164706)
		ui.b.content.TextColor3 = Color3.new(0.682353, 0.752941, 0.784314)
	end)
	ui.b.content.MouseButton1Click:Connect(function()
		local editor = getPageData("Code Editor")
		local compiler = getPageData("Compiler Console")

		if not editor then return warn("getUI(Code Editor): returned nil.") end
		if not compiler then return warn("getUI(Compiler Console): returned nil.") end
		disable(nil, ui)
		compiler:forceOpen()
		local answer = compiler:custom(ui.Editor.TextBox.Text)
		print(answer)
		if answer == false then
			--disable(nil, ui)
			editor:forceOpen()
			popup("failed to run code, maybe something is already running?", 2, UDim2.new(0,0,0,0), true)
			return;
		end
		
		--compiler.ui:WaitForChild("input").Text = ui.Editor.TextBox.Text
		--compiler.ui:WaitForChild("input"):CaptureFocus()
		
		--[[if not firstTime then
			firstTime = true
			ui.Editor.TextBox.Text = ui.Editor.TextBox.Text .. "\nNot working! :l"
		else
			ui.Editor.TextBox.Text = ui.Editor.TextBox.Text .. "\nStill not working... :l"
		end]]
	end)
	return enable, disable, nil;
end

return a
