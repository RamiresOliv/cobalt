local _module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local global = ReplicatedStorage:WaitForChild("global")
local values = global:WaitForChild("values")

_module.lerp = function(a: number, b: number, t: number)
	return a + (b - a) * t
end

_module.typeof = function(thing)
	local tpf = typeof(thing)
	if tpf == "table" then tpf = "list" end
	return tpf
end

_module.fixType = function(str)
	if str == "table" then str = "list" end
	return str
end

_module.concat = function(list: {any}, separator: string)
	for i, v in pairs(list) do
		list[i] = tostring(v)
	end
	return table.concat(list, (separator or " "))
end

_module.stringToHex = function(str)
	return (str:gsub('.', function (c)
		return string.format('%02X', string.byte(c))
	end))
end

_module.hexToString = function(str: string)
	return (str:gsub('..', function (c)
		return string.char(tonumber(c, 16))
	end))
end

_module.getPath = function(dir, utils)
	local progress = values.cd.Value
	local tabled = nil
	
	if progress == nil then
		values.cd.Value = ReplicatedStorage.root
		return true, values.cd.Value
	end

	local function work(toSolve)
		--toSolve = toSolve:gsub("Ç^_SPACE_^Ç", " ")

		if toSolve == "root" then
			progress = utils.root
		elseif toSolve == ".." then
			if values.cd.Value ~= utils.root then
				progress = progress.Parent
				return true
			else
				return false, "invalid parent. It's the limit."
			end
		elseif toSolve == "." then
			progress = progress
			return true
		else
			if progress:FindFirstChild(toSolve) and progress:FindFirstChild(toSolve):IsA("ValueBase") or 
				progress:FindFirstChild(toSolve) and progress:FindFirstChild(toSolve):IsA("Folder") then
				local ffc = progress:FindFirstChild(toSolve)
				if ffc then
					progress = ffc
					return true
				else
					return false, "thing not found or is not the same type - 2 what"
				end
			else
				return false, "thing not found or is not the same type - 1"
			end
		end
	end

	if string.sub(dir, 1, 4) == "root" then
		progress = ReplicatedStorage.root
	end
	if string.find(dir, "/") then
		tabled = string.split(dir, "/")
		for i, v in pairs(tabled) do
			local r, desc = work(v)

			if r == false then
				return false, desc
			end
		end
	else
		local r, desc = work(dir)

		if r == false then
			return false, desc
		end
	end

	return true, progress
end

_module.getFullPath = function(instance: Instance, utils)
	local path = ""
	local lastParent = instance.Parent
	local rootFound = false
	
	path = instance.Name
	repeat
		path = lastParent.Name .. "/" .. path
		lastParent = lastParent.Parent
		if lastParent == ReplicatedStorage.root then
			path = lastParent.Name .. "/" .. path
			rootFound = true
		end
	until rootFound == true
	
	return path
end

return _module
