local me = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local temporaryFolder = ReplicatedStorage:WaitForChild("temporary")
local lp = Players.LocalPlayer
local p = script.Parent
local arguments = require(p.arguments)
local utils = require(p.utils)
local types = require(p.types)
local refs = require(p.references)

local cd = ReplicatedStorage:WaitForChild("root")
local temporary = {}

temporary.clear = function()
	for i, v in pairs(temporaryFolder.functions:GetChildren()) do
		if v:IsA("StringValue") then
			v:Destroy()
		end
	end
	for i, v in pairs(temporaryFolder.values:GetChildren()) do
		if v:IsA("StringValue") then
			v:Destroy()
		end
	end
end
function splitParentheses(str)
	local result = {}
	local level = 0
	local start_index = 1
	for i = 1, #str do
		local char = str:sub(i, i)
		if char == '(' then
			if level == 0 then
				start_index = i
			end
			level = level + 1
		elseif char == ')' then
			level = level - 1
			if level == 0 then
				table.insert(result, str:sub(start_index, i))
			end
		end
	end
	return result
end
function getLine(things)
	things = things:sub(2, -2)
	local args = {}
	local i = 1
	local len = #things
	local inQuotes = false
	local nestedLevel = 0
	local currentArg = ""
	while i <= len do
		local char = things:sub(i, i)
		if char == '"' then
			inQuotes = not inQuotes
			currentArg = currentArg .. char
		elseif char == "(" and not inQuotes then
			nestedLevel = nestedLevel + 1
			currentArg = currentArg .. char
		elseif char == ")" and not inQuotes then
			nestedLevel = nestedLevel - 1
			currentArg = currentArg .. char
		elseif char == "[" and not inQuotes then
			nestedLevel = nestedLevel + 1
			currentArg = currentArg .. char
		elseif char == "]" and not inQuotes then
			nestedLevel = nestedLevel - 1
			currentArg = currentArg .. char
		elseif char == " " and not inQuotes and nestedLevel == 0 then
			if #currentArg > 0 then
				table.insert(args, currentArg)
				currentArg = ""
			end
		else
			currentArg = currentArg .. char
		end
		i = i + 1
	end
	if #currentArg > 0 then
		table.insert(args, currentArg)
	end
	return args
end

function me:run(code, rawArgs, console, mr)
	local proccess = 0
	if mr == nil then mr = false end
	if not code then return {false, "empty request."} end

	local success, returns = pcall(function()
		local lines = code:gsub("\n?;[^\n]*", ""):gsub("	", ""):split("\n")
		local lines_concats = table.concat(lines, " ")
		for match in lines_concats:gmatch("%b()") do
			proccess += 1

			local base_args = getLine(match)
			local base_funcName = table.remove(base_args, 1)

			if not base_funcName then return {false, 'Incomplete statement.'} end

			local scriptFuncFound = temporaryFolder.functions:FindFirstChild(base_funcName)
			local functionData = types.mapping[base_funcName]

			if scriptFuncFound == nil and functionData == nil then return {false, "unknown syntax/function: '" .. (base_funcName or "nil") .. "'"} end

			-- translate args:
			for i, v: string in base_args do
				base_args[i] = arguments:indexArgHandler(v, rawArgs)
			end

			-- native functions:
			local function describe(value, expected)
				-- function, string, boolean, number, list.
				local canStringfy = false
				local vType = typeof(value)

				if vType == "number" and expected == "string" then
					canStringfy = true
				elseif vType == "boolean" and expected == "string" then
					canStringfy = true
				end

				if vType == "string" then -- must have 2 checks, if is a TRUE string or a function.
					if value:sub(1, 1) == '(' and value:sub(-1) == ')' then
						local functionName = value:sub(2, -2):split(" ")[1]
						local typesOfFunc = types.mapping[functionName]

						if not typesOfFunc then return "function" end

						for i, v in typesOfFunc.returns:split("/") do
							if v == "any" or expected == "any" or v == expected then
								if vType == "number" and expected == "string" then
									canStringfy = true
								elseif vType == "boolean" and expected == "string" then
									canStringfy = true
								end
								return v, canStringfy
							end
						end

						return "function"
					elseif value:sub(1, 1) == '[' and value:sub(-1) == ']' then
						return "list"
					else 
						return "string"
					end
				else
					return vType, canStringfy
				end
			end

			if functionData then
				if #base_args < functionData.requiredEntries then return {false, "[" .. base_funcName .. "] expected " .. tostring(functionData.requiredEntries) .. " entries, but received " .. tostring(#base_args)} end

				for i_args, v_args in base_args do
					local funcType = types.mapping[base_funcName]
					local argExpects = funcType.params[i_args]

					if funcType.openEntries == true and i_args > #funcType.params then
						argExpects = funcType.params[#funcType.params]
					elseif argExpects == nil then
						continue
					end

					local foundExpect = false
					for i, v in pairs(argExpects:split("/")) do
						local vType, stringfy = describe(v_args, functionData.params[#functionData.params])
						if v == "any" or vType == "any" or vType == "function" or v == vType then
							foundExpect = true
							break
						end
					end

					if not foundExpect then
						return {false, "[" .. base_funcName .. "] expected " .. tostring(argExpects) .. " but received [" .. tostring(i_args) .. "]: '" .. utils.typeof(v_args) .. "'"}
					end
				end

				local funcRefFunc = refs[base_funcName]
				if not funcRefFunc then return {false, "Function reference doesn't exists. (prob of a huge bug)"} end

				local state, data, refuseStop = funcRefFunc(base_args, {
					p = lp,
					root = cd,
					console = console
				})
				
				-- am losing my head.
				if data ~= nil and typeof(data) == "table" and data[1] == "_-!@!_-!-return-and-stop-rn!" then return {true, data[2], nil, true} end
				if data ~= nil and typeof(data) == "table" and data[1] == "_-!@!_-!-continue-skip-this-thing-rn!"
					or data ~= nil and typeof(data) == "table" and data[1] == "_-!@!_-!-break-and-stop-rn!" then return {true, nil, nil, true} end
				if state == false then return {false, data} end
				if mr == true then return {true, data, refuseStop} end
			elseif scriptFuncFound then
				-- script functions

				local s, decode = pcall(function()
					return game:GetService("HttpService"):JSONDecode(scriptFuncFound.Value)
				end)
				if not s then 
					console:write("[scriptFunction:ivalid_JSON]: JSONDecode failed.", "red")
					return {false, "Unable to run function, JSONDecode was unable to work with it."}
				end
				if typeof(decode) ~= "table" or not decode.arguments or not decode.commands then
					warn("invalid function data format")
					console:write("[scriptFunction:ivalid_format]: Invalid function data format to run, JSONDecode was successfully, but the data wasn't expected.", "red")
					return {false, "Invalid function data format to run, JSONDecode was successfully, but the data wasn't expected."}
				end

				local function run(c)
					for i, name in decode.arguments do
						c = c:gsub("{" .. name .. "}", tostring(base_args[i]))
					end

					local r, returns = me:run(c, nil, console, true)
					
					if r[1] == false then
						console:write("[" .. base_funcName .. "] Error origin in function '" .. base_funcName .. "': " .. tostring(r[2] or "unknown"), "red")
						return {false, r[2]}
					end
					
					if mr == true then
						return {true, arguments:indexArgHandler(r[2], rawArgs), r[4]}
					end
				end

				local get
				if typeof(decode) == "table" then
					for i, c in decode.commands do
						get = run(c)
						if get[3] == true then break end
						if typeof(get) == "table" and get[1] == false then break end
					end
				else
					get = run(tostring(decode.commands))
					if get[3] == true then break end
					if typeof(get) == "table" and get[1] == false then break end
				end

				if get ~= nil then
					return get
				end

			end
			
		end
	end)

	if not success then
		warn("[index.mluau]: High level error:")
		warn(returns)
		temporary:clear()
		return {false, returns}
	elseif typeof(returns) == "table" and returns[1] == false then
		temporary:clear()
		return {false, returns[2]}
	else
		if not returns then
			temporary:clear()
			return {true}
		else
			return returns
		end
	end
	-- return handler, this will lead us to a good end... Or not.
end

function me:fixArgs(player, code, rawArgs)
	for match in code:gmatch("%b()") do
		local args = getLine(match)
		for i, v: string in args do
			args[i] = arguments:indexArgHandler(v, rawArgs)
		end
	end

	return code
end

return me