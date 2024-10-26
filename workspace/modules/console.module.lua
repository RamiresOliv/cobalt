--[[

better version for new UI update.

]]

local console = {}

local colors = {
	default = "#dedede",
	highlight = "#4992ff",
	muted = "#3d3d3d",
	highview = "#8c4aff",
	yellow = "#ffff00",
	red = "#ff6b6b",
	green = "#8aff8a",
	blue = "#4f4fff",
	white = "#ffffff",
	black = "#000000",
}

function updateLineCounts(obj: TextLabel, list, toCountList)
	for i, v in pairs(list:GetChildren()) do
		if v:IsA("TextLabel") then
			v:Destroy()
		end
	end
	
	local i = 0
	for _, v in pairs(toCountList:GetChildren()) do
		if v:IsA("TextLabel") then
			i += 1
			local lineCount = obj:Clone()
			lineCount.Parent = list
			lineCount.Size = UDim2.new(0, lineCount.Size.X.Offset, 0, v.AbsoluteSize.Y)
			lineCount.Text = tostring(i)
			lineCount.Visible = true
		end
	end
end

local changeCnn;
function console.init(player, templates: Folder, c: ScrollingFrame)
	local _local = {}
	local self = {}

	_local.inputEventI = Instance.new("BindableEvent")

	self.inputEventConnection = nil
	self.inputEvent =  _local.inputEventI.Event
	self.currentInput = nil


	local anyInputSizeUpdate = false
	local stopInputSizeUpdate = false
	local stoppedInputSizeUpdate = false
	
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if self.currentInput then
			c.CanvasPosition = Vector2.new(0, c.CanvasSize.Y.Offset + self.currentInput.AbsoluteSize.Y);
		end
	end)
	
	c.list.ChildAdded:Connect(function()
		updateLineCounts(templates.line, c.lines, c.list)
	end)
	
	function self:write(text, cr: string, bgProfile: string, centered)
		local bg = nil
		if bgProfile then
			bg = colors[bgProfile]
		end
		if cr then
			cr = colors[cr]
		end
		
		local i: Instance = templates["label"]:Clone()
		if i:IsA("TextLabel") then
			if #text > 200000 then
				i.Text = "Unable to print. (#text > 200000)" -- text:gsub("<[^>]*>", "")
			else
				i.Text = text
			end
			if centered then
				i.TextXAlignment = Enum.TextXAlignment.Center
			end
			if cr ~= nil then
				i.TextColor3 = Color3.fromHex(cr or colors.default)
			end
			if bg ~= nil then
				i.BackgroundTransparency = 0
				i.BackgroundColor3 = Color3.fromHex(bg or "#000000")
			end
		end

		i.Visible = true
		i.Parent = c.list
		c.CanvasSize = UDim2.new(0,0,c.CanvasSize.Y.Scale,
			c.CanvasSize.Y.Offset + i.AbsoluteSize.Y)
		task.wait();
		c.CanvasPosition = Vector2.new(0, c.CanvasSize.Y.Offset + i.AbsoluteSize.Y);
	end
	function self:getWrotes()
		local c_gc = c.list:GetChildren()
		local r = {}
		for i, v in pairs(c_gc) do
			if v:IsA("TextLabel") or v:IsA("TextBox") then
				table.insert(r, v.Text)
			end
		end
		return r
	end
	function self:clear()
		local c_gc = c.list:GetChildren()
		
		for i, v in pairs(c_gc) do
			if not v:IsA("UIBase") then
				v:Destroy()
			end
		end
		
		c.CanvasSize = UDim2.new(0, 0, 0, 0)
		c.CanvasPosition = Vector2.new(0, 0);
		updateLineCounts(templates.line, c.lines, c.list)
	end
	
	function self:newInput(text)
		local inputData = {}
		
		local input: TextBox = c.Parent.input
		input.PlaceholderText = (tostring(text) or "")
	
		self.inputEventConnection = input.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				_local.inputEventI:Fire(input.Text)
				if self.inputEventConnection then
					self.inputEventConnection:Disconnect()
				end
			end
		end)
		
		input:CaptureFocus()
		
		return inputData
	end
	
	function self:askUser(placeHolder)
		local inputData = {}

		local input: TextBox = c.Parent.input
		local text = input.Text
		input.Text = ""
		input.TextEditable = true
		input.TextColor3 = Color3.new(0.631373, 0.631373, 0.631373)
		input:CaptureFocus()
		input.PlaceholderText = (tostring(placeHolder) or "")

		self.inputEventConnection = input.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				input.TextEditable = false
				input.TextColor3 = Color3.new(0.223529, 0.223529, 0.223529)
				_local.inputEventI:Fire(input.Text)
				if self.inputEventConnection then
					self.inputEventConnection:Disconnect()
				end
				input.Text = text
			end
		end)

		return inputData
	end

	function self:inputFocus(data)
		c.Parent.input:CaptureFocus()
	end
	
	function self:inputSet(data)
		c.Parent.input.Text = (tostring(data) or "...")
	end
	
	function self:color(text: string, profile: string)
		local send = colors[profile]
		if not send then
			send = profile
		end

		return `<font color="{send}">{tostring(text)}</font>`
	end
	
	return self
end

return console
