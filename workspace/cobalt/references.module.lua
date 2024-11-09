-- test, hello world!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local global = ReplicatedStorage:WaitForChild("global")
local temporary = ReplicatedStorage:WaitForChild("temporary")
local values = global:WaitForChild("values")
local p = script.Parent
local _local = {}
local refs = {
	_self = {}
}
function refs._self.refs_size()
	local size = 0
	for i, v in refs do
		size += 1
	end
	return size - 1
end

local utils = require(p.utils)
local language = require(p.language)
_local.lerp = utils.lerp
_local.concat = utils.concat
_local.typeof = utils.typeof
_local.hexToString = utils.hexToString
_local.stringToHex = utils.stringToHex
_local.getPath = utils.getPath
_local.getFullPath = utils.getFullPath

local types = require(p.types)
local arguments = require(p.arguments)

local function jsonObjToTable(json_obj)
	local v = HttpService:JSONDecode(json_obj)

	local function convertTable(t)
		local result = {}
		local total = 0

		for _, value in pairs(t) do
			total = total + 1
			if typeof(value) == "table" then
				result[total] = convertTable(value)
			else
				result[total] = value
			end
		end

		return result
	end

	if typeof(v) == "table" then
		return convertTable(v)
	else
		return v
	end
end

function _local.tableToString(list)
	local dat = "["
	if typeof(list) ~= "table" then
		return nil
	end
	for i, v in list do
		if typeof(v) == "table" then
			v = _local.tableToString(v)
		end

		if i == #list then dat = dat .. tostring(v)
		else dat = dat .. tostring(v) .. ", " end
	end
	dat = dat .. "]" return dat
end

-- args parts:
function resolve_args(v, utils, allowSpecificReturns)
	-- check if has ()
	
	if typeof(v) == "string" then
		if string.sub(v, 1, 8) == "_!str!_-" then
			local hex = string.sub(v, 9)
			local str = _local.hexToString(hex)
			v = str
		elseif string.sub(v, 1, 8) == "_!fmt!_-" then
			v = string.sub(v, 9)
		end
	end

	if typeof(v) == "string" then
		for _, v_var in pairs(temporary.values:GetChildren()) do
			if v_var:IsA("StringValue") then
				local togoV = v_var.Value

				if togoV == "true" then
					togoV = true
				elseif togoV == "false" then
					togoV = false
				elseif togoV == "nil" then
					togoV = nil
				end

				local toNumberPcallSuccess, r = pcall(function() return tonumber(tostring(togoV)) end)

				local togo = tostring(togoV)
				if string.find(tostring(togoV), " ") then
					togo = '"' .. tostring(togoV) .. '"'
				end

				if toNumberPcallSuccess and r ~= nil then
					togo = tostring(r)
				end

				if typeof(togoV) == "boolean" then
					togo = tostring(togoV)
				elseif typeof(togoV) == "string" and string.sub(togoV, 1, 1) == "[" and string.sub(togoV, -1, -1) == "]" then
					togo = togoV
				end

				--[[local final = togo
				if string.sub(togoV, 1, 1) == "{" and string.sub(togoV, -1, -1) == "}" then
					final = '"' .. togo .. '"'
				end]]


				local final = togo
				if string.sub(tostring(togoV), 1, 1) == "{" and string.sub(tostring(togoV), -1, -1) == "}" then
					final = '"' .. string.gsub(togoV, '"', "_$#@¨COMMA_CHAR¨@#$_") .. '"'
				end


				final = final:gsub("%%", "#")
				v = v:gsub("{" .. v_var.Name .. "}", final)
			end
		end

		local constants = require(script.Parent.constants)()
		if typeof(v) == "string" then
			for i_, v_ in constants do
				local a = constants[i_]
				v = v:gsub("{" .. tostring(i_) .. "}", tostring(a))
			end
		end
	end
	
	local thingToReturn = nil
	if typeof(v) == "string" and v:sub(1, 1) == '(' and v:sub(-1) == ')' then
		local compilation = require(script.Parent.index):run(v, nil, utils.console, true)

		thingToReturn = compilation[4]

		if compilation[1] == false then
			if typeof(compilation[2]) == "table" then
				return {false, "[sub-function]: " .. compilation[2][2]}
			else
				return {false, "[sub-function]: " .. compilation[2]}
			end
		end
		local ohmy = compilation

		if compilation[3] ~= true then
			if typeof(compilation[2]) == "table" then
				local a = _local.resolveArgs(compilation[2], utils)
				ohmy[2] = a
			else
				ohmy[2] = _local.resolveSpecificArgs(compilation[2], utils, allowSpecificReturns)
			end
		end
		if ohmy[1] == "_!!dDecodePSCFail!!_" then return false, ohmy[2] end
		v = ohmy[2]
	elseif typeof(v) == "string" and v:sub(1, 1) == '[' and v:sub(-1, -1) == ']' then
		v = v:sub(2, -2)

		local rendered_table = {}
		for value in v:gmatch("([^,]+)") do
			value = value:match("^%s*(.-)%s*$")
			local dec = _local.resolveSpecificArgs(value, utils)
			if typeof(dec) == "table" and dec[1] == false or typeof(dec) == "table" and dec[1] == "_!!dDecodePSCFail!!_" then 
				return {false, dec[2]} 
			end

			table.insert(rendered_table, dec)
		end

		local result = {}
		local stack = {result}
		
		local currentTable = result

		for _, value in ipairs(rendered_table) do
			if typeof(value) == "string" then
				local openBrackets = select(2, value:gsub("%[", ""))
				local closeBrackets = select(2, value:gsub("%]", ""))

				local cleanValue = value:gsub("%[", ""):gsub("%]", "")

				for _ = 1, openBrackets do
					local newTable = {}
					table.insert(currentTable, newTable)
					table.insert(stack, currentTable)
					currentTable = newTable
				end

				if cleanValue ~= "" then
					local rSA = _local.resolveSpecificArgs(arguments:indexArgHandler(cleanValue), utils)
					if typeof(rSA) == "table" and rSA[1] == "_!!dDecodePSCFail!!_" then return {false, "[sub-function]: " .. tostring(rSA[2])} end
					table.insert(currentTable, rSA)
				end

				for _ = 1, closeBrackets do
					if #stack > 0 then
						currentTable = table.remove(stack)
					end
				end
			else
				table.insert(currentTable, value)
			end
		end

		v = result
	end

	if not allowSpecificReturns then
		if typeof(v) == "string" then
			if v == "_-!@!_-!-continue-skip-this-thing-rn!" or v == "_-!@!_-!-break-and-stop-rn!" then
				v = nil
			end
		end
	end
	
	if typeof(v) == "string" then
		v = string.gsub(v, "_$#@¨COMMA_CHAR¨@#$_", '"')
	end

	local toNumberPcallSuccess, n = pcall(function()
		return tonumber(v)
	end)
	if toNumberPcallSuccess and n ~= nil then
		v = n
	end

	return {true, v}, thingToReturn
end
function _local.resolveArgs(args, utils)

	for i, v in args do
		local dec = resolve_args(v, utils, false)
		if dec[1] == false then return {"_!!dDecodePSCFail!!_", dec[2]} end
		args[i] = dec[2]
	end

	return args
end
function _local.resolveSpecificArgs(args, utils, allowSpecificReturns)
	local dec, ohgod = resolve_args(args, utils, (allowSpecificReturns or false))
	if dec[1] == false then return {"_!!dDecodePSCFail!!_", dec[2]} end

	return dec[2], ohgod
end

-- refs defines:
refs["var"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	
	if not args[1] or typeof(args[1]) ~= "string" then
		return false, "[var] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local ffc = temporary.values:FindFirstChild(tostring(args[1]))
	if ffc and ffc:IsA("StringValue") then
		if typeof(args[2]) == "table" then
			ffc.Value = game:GetService("HttpService"):JSONEncode(args[2])--:gsub('"', "")
		else
			ffc.Value = tostring(args[2])
		end
	else
		local variable = Instance.new("StringValue", temporary.values)
		variable.Name = tostring(args[1])

		if typeof(args[2]) == "table" then
			variable.Value = game:GetService("HttpService"):JSONEncode(args[2])--:gsub('"', "")
		else
			variable.Value = tostring(args[2])
		end
	end
	
	--local r, err = utils.set_variable(args[1], args[2])
	return true
end
refs["prompt"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if not args[1] then
		args[1] = "script is asking something"
	end

	local stop = false
	local answer = nil
	utils.console:askUser(tostring(args[1]))

	utils.console.inputEvent:Once(function(content: string)
		answer = tostring(content)
		stop = true
	end)

	repeat
		task.wait(.1)
	until answer ~= nil or stop == true

	local r = _local.stringToHex(answer)
	return true, "_!str!_-" .. tostring(r)
end
refs["pairs"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" then
		return false, "[listrem] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local togo = {}

	for i, v in pairs(args[1]) do
		togo[i] = v
	end

	return true, togo
end
refs["ipairs"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" then
		return false, "[listrem] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local togo = {}

	for i, v in ipairs(args[1]) do
		togo[i] = v
	end

	return true, togo
end
refs["run"] = function(args, utils)
	local s, a = require(p.index):run(table.concat(args, " "), nil, utils.console, true)
	return true, {s[1], a or s[2] or nil}
end
refs["spawn"] = function(args, utils)
	if not typeof(args[1]) then
		return false, "[spawn] expected a any value but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	spawn(function()
		require(p.index):run(table.concat(args, " "), nil, utils.console, true)
	end)

	return true
end
refs["get"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if not args[1] or typeof(args[1]) ~= "string" then
		return false, "[get] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local ffc = temporary.values:FindFirstChild(tostring(args[1]))
	local args = nil
	if ffc and ffc:IsA("StringValue") then
		args = ffc.Value
	end

	--local r, err = utils.set_variable(args[1], args[2])
	return true, args
end
refs["print"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	for i, v in args do
		local go = "undefined"
		local args1Type = typeof(v)
		if args1Type == "string" then
			if v == "_-!@!_-!-continue-skip-this-thing-rn!" or v == "_-!@!_-!-break-and-stop-rn!" then
				go = ""
			else
				if string.sub(v, 1, 1) == '"' and string.sub(v, -1, -1) == '"' then
					go = string.sub(tostring(v), 2, -2)
				else
					go = tostring(v)
				end
			end
		elseif args1Type == "number" or args1Type == "boolean" then
			go = utils.console:color(tostring(v), "yellow")
			--elseif args1Type == "nil" then
			--	go = ""
		elseif args1Type == "table" then
			local isNumberIndex = false
			for v_index, _ in v do
				if type(v_index) == "number" then
					isNumberIndex = true
					break
				else
					isNumberIndex = false
					break
				end
			end

			if isNumberIndex then
				local function readTable(t)
					local togo = "["
					if #t == 0 then
						togo = togo .. "]"
					else
						for i, v in ipairs(t) do
							if type(v) == "table" then
								if i == #t then
									togo = togo .. "" .. readTable(v) .. "]"
								else
									togo = togo .. "" .. readTable(v) .. ", "
								end
							else
								local valueConversion = function(rawValue)
									if typeof(rawValue) == "string" then
										return utils.console:color('"' .. tostring(v) .. '"', "green")
									else
										return utils.console:color(tostring(v), "yellow")
									end
								end

								if i == #t then
									togo = togo .. valueConversion(v) .. "]"
								else
									togo = togo .. valueConversion(v) .. ", "
								end
							end
						end
					end
					-- Remove a última vírgula e espaço, se existirem
					return togo
				end
				go = readTable(v)
			else
				go = game:GetService("HttpService"):JSONEncode(v)
			end
		end

		utils.console:write(go or "nil")
	end
end
refs["println"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local toPrint = {}
	for i, v in args do
		local go = "undefined"
		local args1Type = typeof(v)
		if args1Type == "string" then

			if v == "_-!@!_-!-continue-skip-this-thing-rn!" or v == "_-!@!_-!-break-and-stop-rn!" then
				go = ""
			else
				go = tostring(v)
			end
		elseif args1Type == "number" or args1Type == "boolean" then
			go = utils.console:color(tostring(v), "yellow")
			--elseif args1Type == "nil" then
			--	go = "nil"
		elseif args1Type == "table" then
			local function readTable(t)
				local togo = "["
				if #t == 0 then
					togo = togo .. "]"
				else
					for i, v in ipairs(t) do
						if type(v) == "table" then
							if i == #t then
								togo = togo .. "" .. readTable(v) .. "]"
							else
								togo = togo .. "" .. readTable(v) .. ", "
							end
						else
							local valueConversion = function(rawValue)
								if typeof(rawValue) == "string" then
									return utils.console:color('"' .. tostring(v) .. '"', "green")
								else
									return utils.console:color(tostring(v), "yellow")
								end
							end

							if i == #t then
								togo = togo .. valueConversion(v) .. "]"
							else
								togo = togo .. valueConversion(v) .. ", "
							end
						end
					end
				end
				return togo
			end

			go = readTable(v)
		end

		table.insert(toPrint, go)
	end

	utils.console:write(table.concat(toPrint, " "))
end
refs["clear"] = function(args, utils)
	utils.console:clear()
	return true
end
refs["for"] = function(args, utils) -- complex
	local operator = _local.resolveSpecificArgs(table.remove(args, 1), utils)
	if typeof(operator) == "table" and operator[1] == "_!!dDecodePSCFail!!_" then return false, operator[2] end

	local loopArgs = {}
	local commands = {}
	for i, v in pairs(args) do
		if typeof(v) == "string" then
			if v:sub(1, 1) == '(' and v:sub(-1) == ')' then
				table.insert(commands, v)
			else
				table.insert(loopArgs, v)
			end
		end
	end

	local function loopa(i, v)
		--task.wait()
		for _, c in commands do
			local translated_v, r = _local.resolveSpecificArgs(v, utils, true)
			c = c:gsub("{" .. (loopArgs[1] or "_index") .. "}", tostring(i))
			c = c:gsub("{" .. (loopArgs[2] or "_value") .. "}", tostring(translated_v))

			local r, returns = require(p.index):run(c, nil, utils.console, true)

			if r[1] == false then return false, "[for] function error [" .. tostring(i) .. "]: " .. r[2] end
			--[[if r[2] then
				return true, returns or r[2]
			end]]
		end
	end
	if typeof(operator) == "table" then
		for index, value in operator do
			local a, b = loopa(index, value)

			if a ~= nil then
				if b == "_-!@!_-!-continue-skip-this-thing-rn!" then
					continue
				elseif b == "_-!@!_-!-break-and-stop-rn!" then
					break
				end
				--return a, b
			end
		end
	elseif typeof(operator) == "number" then
		for index = 1, operator do
			local a, b = loopa(index, "nil")

			if a ~= nil then
				if b == "_-!@!_-!-continue-skip-this-thing-rn!" then
					continue
				elseif b == "_-!@!_-!-break-and-stop-rn!" then
					break
				end
				--return a, b
			end
		end
	else
		return false, "[for] expected a number or a list but received [1]: '" .. _local.typeof(operator) .. "'"
	end

	return true
end
refs["function"] = function(rawArgs, utils)
	--args = _local.resolveArgs(args, utils)

	local func_name = table.remove(rawArgs, 1)
	local args = {}
	local cmds = {}

	for i, v in pairs(rawArgs) do
		if typeof(v) == "string" then
			if v:sub(1, 1) == '(' and v:sub(-1) == ')' then
				table.insert(cmds, v)
			else
				table.insert(args, v)
			end
		end
	end

	local ffc = temporary.functions:FindFirstChild(func_name)
	if ffc and ffc:IsA("StringValue") then
		ffc.Value = game:GetService("HttpService"):JSONEncode({
			arguments = args,
			commands = cmds
		})
	else
		local newFunc = Instance.new("StringValue", temporary.functions)
		newFunc.Name = tostring(func_name)
		newFunc.Value = game:GetService("HttpService"):JSONEncode({
			arguments = args,
			commands = cmds
		})
	end

	--local a, b = utils.set_function(func_name, args, commands)
	return true
end
refs["if"] = function(args, utils)
	--args = _local.resolveArgs(args, utils)
	local condition = table.remove(args, 1)
	local choosen = nil
	local elseFound = false
	local true_commands = {}
	local false_commands = {}
	for i, v in pairs(args) do
		if typeof(v) == "string" then
			if v:sub(-1, -1) == ')' then
				if not elseFound then
					table.insert(true_commands, v)
				else
					table.insert(false_commands, v)
				end
			elseif v == "else" then
				elseFound = true
			end
		end
	end

	local togo = nil
	local a = _local.resolveSpecificArgs(condition, utils)
	if a and tostring(a) == "true" then
		for i, v in true_commands do
			local r, ohno = _local.resolveSpecificArgs(v, utils, true)
			if typeof(r) == "table" and r[1] == "_!!dDecodePSCFail!!_" then return false, r[2] end

			if r == "_-!@!_-!-continue-skip-this-thing-rn!" or r == "_-!@!_-!-break-and-stop-rn!" then
				return true, r
			end
			if ohno == true then
				return true, {"_-!@!_-!-return-and-stop-rn!", r}
			end
		end
	else
		for i, v in false_commands do
			local r, ohno = _local.resolveSpecificArgs(v, utils, true)
			if typeof(r) == "table" and r[1] == "_!!dDecodePSCFail!!_" then return false, r[2] end

			if r == "_-!@!_-!-continue-skip-this-thing-rn!" or r == "_-!@!_-!-break-and-stop-rn!" then
				return true, r
			end
			if ohno == true then
				return true, {"_-!@!_-!-return-and-stop-rn!", r}
			end
		end
	end

	return true, nil
end
refs["type"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local typeofit = typeof(args[1])

	if typeofit == "table" then
		typeofit = "list"
	elseif typeofit == "nil" then
		typeofit = "nil"
	end

	return true, typeofit
end
refs["true"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, (not not args[1])
end
refs["inf"] = function(args, utils)
	return true, math.huge
end
refs["nothing"] = function(args, utils)
	return true, ""
end
refs["space"] = function(args, utils)
	return true, " "
end
refs["break"] = function(args, utils)
	return true, "_-!@!_-!-break-and-stop-rn!"
end
refs["continue"] = function(args, utils)
	return true, "_-!@!_-!-continue-skip-this-thing-rn!"
end
refs["return"] = function(args, utils)
	args = _local.resolveArgs(args, utils)

	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local togo = {"_-!@!_-!-return-and-stop-rn!"}
	table.insert(togo, args[1])

	return true, togo
end
refs["return-if"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local func = table.remove(args, 1)
	if typeof(func) ~= "boolean" then
		return false, "[return-if] expected a boolean but received [1]: '" .. _local.typeof(func) .. "'"
	end

	local togo = nil
	if func == true then
		togo = {"_-!@!_-!-return-and-stop-rn!"}
		table.insert(togo, args[1])
	end

	return true, togo
end
refs["not"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, (not args[1])
end
refs["and"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	local r = true

	for i, v in args do
		local argsReq = _local.resolveSpecificArgs(v, utils)
		if typeof(argsReq) == "table" and argsReq[1] == "_!!dDecodePSCFail!!_" then return {false, args[2]} end
		if argsReq == false then
			r = false
			break
		end
	end

	return true, r
end
refs["or"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	local r = false

	for i, v in args do
		local argsReq = _local.resolveSpecificArgs(v, utils)
		if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
		if argsReq == true then
			r = true
			break
		end
	end

	return true, r
end
refs["=="] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, (args[1] or nil) == (args[2] or nil)
end
refs["!="] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, (args[1] or "_ITSNIL!!!!!!!!!") ~= (args[2] or "_ITSNIL!!!!!!!!!")
end
refs["nil?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) == nil or args[1] == nil or not args[1] then
		return true, true
	else
		return true, false
	end
end
refs[">"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[>] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[>] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local success, r = pcall(function()
		return tonumber(args[1]) > tonumber(args[2])
	end)

	if not success then return false, `error in try compare: {_local.typeof(args[1])} > {_local.typeof(args[2])}` end

	return true, r
end
refs["<"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[<] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[<] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local success, r = pcall(function()
		return tonumber(args[1]) < tonumber(args[2])
	end)

	if not success then return false, `error in try compare: {_local.typeof(args[1])} < {_local.typeof(args[2])}` end

	return true, r
end
refs[">="] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[>=] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[>=] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local success, r = pcall(function()
		local d = args[1] >= args[2]
		return d
	end)

	if not success then return false, `error in try compare: {_local.typeof(args[1])} >= {_local.typeof(args[2])}` end

	return true, r
end
refs["<="] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[<=] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[<=] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local success, r = pcall(function()
		local d = args[1] <= args[2]
		return d
	end)

	if not success then return false, `error in try compare: {_local.typeof(args[1])} <= {_local.typeof(args[2])}` end

	return true, r
end
refs["str"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local toGo = _local.concat(args, " ")
	if toGo:sub(1, 1) == '"' and toGo:sub(-1) == '"' then
		toGo = toGo:sub(2, -2)
	end

	local hex = _local.stringToHex(toGo)
	return true, "_!str!_-" .. tostring(hex)
end
refs["str!"] = function(args, utils)
	local toGo = _local.concat(args, " ")
	if toGo:sub(1, 1) == '"' and toGo:sub(-1) == '"' then
		toGo = toGo:sub(2, -2)
	end

	local hex = _local.stringToHex(toGo)
	return true, "_!str!_-" .. tostring(hex)
end
refs["color"] = function(args, utils)
	local colors = {
		red = "#FF0000",
		green = "#00FF00",
		blue = "#0000FF",
		yellow = "#FFFF00",
		purple = "#800080",
		orange = "#FFA500",
		cyan = "#00FFFF",
		magenta = "#FF00FF",
		black = "#000000",
		white = "#FFFFFF",
		gray = "#808080",
		pink = "#FFC0CB",
		brown = "#A52A2A",
		lime = "#00FF00",
		navy = "#000080",
		blank = "#F7EEDA"
	}

	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])
	args[2] = tostring(args[2])

	if typeof(args[1]) ~= "string" then
		return false, "[color] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "string" then
		return false, "[color] expected a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local color = colors[args[2]]
	if not color then
		local success = pcall(function()
			Color3.fromHex(tostring(args[2]))
		end)

		if not success then
			local clrs = ""
			local times = 0
			for i, v in colors do
				times += 1

				local textColor = v
				if v == "#000000" then
					textColor = colors["blank"]
				end
				if times == 1 then
					clrs = clrs .. `<font color="{textColor}">{i}</font>`
				else
					clrs = clrs .. `<font color="{colors["blank"]}">, </font>` .. `<font color="{textColor}">{i}</font>`
				end
			end
			return false, "[color] invalid color hex or color name. valid names is: " .. clrs .. "."
		end
	end

	if args[2] == "bold" then
		args[1] = `<b>{args[1]}</b>`
	elseif args[2] == "italic" then
		args[1] = `<i>{args[1]}</i>`
	else
		args[1] = `<font color="{(color or "#ff0088")}">{args[1]}</font>`
	end

	local hex = _local.stringToHex(args[1])
	return true, "_!str!_-" .. tostring(hex)
end
refs["format"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	if typeof(args[1]) ~= "string" then
		return false, "[format] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local arg1 = tostring(table.remove(args, 1))
	for i, v in args do
		arg1 = arg1:gsub("{" .. tostring(i) .. "}", tostring(v))
	end

	local hex = _local.stringToHex(arg1)
	return true, "_!str!_-" .. tostring(hex)
end
refs["split"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	if typeof(args[1]) ~= "string" then
		return false, "[split] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local list = string.split(args[1], tostring(args[2] or " "))
	return true, _local.tableToString(list)
end
refs["replace"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	if typeof(args[1]) ~= "string" then
		return false, "[replace] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, string.gsub(tostring(args[1]), tostring(args[2]), tostring(args[3]))
end
refs["len"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" and typeof(args[1]) ~= "table" then
		return false, "[len] expected a string or a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	return true, #args[1]
end
refs["reverse"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" and typeof(args[1]) ~= "table" then
		return false, "[reverse] expected a list or a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if typeof(args[1]) == "table" then
		local newTable = {}
		for i, v in args[1] do
			local value = args[1][math.abs((i - 1) - #args[1])]
			table.insert(newTable, value)
		end

		return true, newTable
	else
		return true, string.reverse(args[1])
	end
end
refs["upper"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	if typeof(args[1]) ~= "string" then
		return false, "[upper] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, string.upper(tostring(args[1]))
end
refs["lower"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	if typeof(args[1]) ~= "string" then
		return false, "[lower] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, string.lower(tostring(args[1]))
end
refs["upper?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	local found = false
	local alphabet = {
		"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
	}

	if typeof(args[1]) ~= "string" then
		return false, "[upper] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local function splitWords(str)
		local words = {}
		for word in string.gmatch(str, ".") do
			table.insert(words, word)
		end
		return words
	end
	local a = splitWords(args[1])
	for i, v in pairs(a) do
		for ai, l in alphabet do
			if v == string.upper(l) then
				found = true
				break
			end
		end
	end

	return true, found
end
refs["lower?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	local found = false
	local alphabet = {
		"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
	}

	if typeof(args[1]) ~= "string" then
		return false, "[upper] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local function splitWords(str)
		local words = {}
		for word in string.gmatch(str, ".") do
			table.insert(words, word)
		end
		return words
	end
	for i, v in pairs(splitWords(args[1])) do
		for ai, l in alphabet do
			if v == string.lower(l) then
				found = true
				break
			end
		end
	end

	return true, found
end
refs["listadd"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local list = table.remove(args, 1)

	if typeof(list) ~= "table" then
		return false, "[listadd] expected a list but received [1]: '" .. _local.typeof(list) .. "'"
	end

	for i, v in args do
		table.insert(list, v)
	end

	local a = _local.tableToString(list)

	return true, a
end
refs["listget"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local list = table.remove(args, 1)

	if typeof(list) ~= "table" then
		return false, "[listget] expected a list but received [1]: '" .. _local.typeof(list) .. "'"
	end
	if typeof(args[1]) ~= "number" then
		return false, "[listget] expected a number but received [2]: '" .. _local.typeof(args[1]) .. "'"
	end

	local success, args = pcall(function()
		return list[args[1]]
	end)

	if not success then
		args = nil
	end

	return true, args
end
refs["listrem"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local list = table.remove(args, 1)

	if typeof(list) ~= "table" then
		return false, "[listrem] expected a list but received [1]: '" .. _local.typeof(list) .. "'"
	end

	for i, v in args do
		local r, n = pcall(function()
			return tonumber(v)
		end)
		if not r then
			return false, "[listrem] argument is not a number: [".. tostring(i) .."]: '" .. tostring(n) .. "'"
		end

		table.remove(list, n)
	end

	return true, _local.tableToString(list)
end
refs["join"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" then
		return false, "[join] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local join = table.concat(args[1], tostring(args[2] or " "))

	return true, join
end
refs["starts?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[starts] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "string" then
		return false, "[starts] expected a list but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	-- args[1]: the string which I want to check if it starts with something.
	-- args[2]: is the thing which I want to check the string if it has.
	return true, (string.sub(args[1], 1, #args[2]) == args[2])
end
refs["ends?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[ends] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "string" then
		return false, "[ends] expected a list but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, (string.sub(args[1], -#args[2], -1) == args[2])
end
refs["skip"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[skip] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[skip] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, string.sub(args[1], args[2])
end
refs["crop"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[skip] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[skip] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	if args[3] and typeof(args[3]) ~= "number" then
		return false, "[skip] expected a number but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end

	return true, string.sub(args[1], args[2], (args[3] or args[2]))
end
refs["first"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[first] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" or args[2] < 0 then
		return false, "[first] expected a positive number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, string.sub(args[1], 0, args[2])
end
refs["last"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[last] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" or args[2] < 0 then
		return false, "[last] expected a positive number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, string.sub(args[1], -args[2], -1)
end
refs["find"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" and typeof(args[1]) ~= "table" then
		return false, "[find] expected a string or a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if typeof(args[1]) == "string" then
		if typeof(args[2]) ~= "string" then
			return false, "[find] expected a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
		end

		return true, string.find(args[1], args[2]) ~= nil
	else
		if typeof(args[1]) ~= "string" and typeof(args[1]) ~= "number" then
			return false, "[find] expected a string or a list or a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
		end

		return true, table.find(args[1], args[2]) ~= nil
	end
end
refs["sort"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" then
		return false, "[sort] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "string" then
		return false, "[sort] expected a function name as a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local toSortList = args[1]
	local sortedList = {}
	-- [1,3,2]: [1,2,3]
	-- local returns = require(p.index):run(`({args[2]} {v} {args[1][i+1]})`, nil, utils.console, true)

	for i = 1, #toSortList - 1 do
		for j = i + 1, #toSortList do
			local v1 = toSortList[i]
			local v2 = toSortList[j]

			if typeof(v1) == "table" then
				v1 = _local.tableToString(v1)
			end
			if typeof(v2) == "table" then
				v2 = _local.tableToString(v2)
			end
			local returns = require(p.index):run(`({args[2]} {v1} {v2})`, nil, utils.console, true)

			if returns[1] == false then
				return false, "[sort] [2] function: "  .. (returns[2] or "")
			end
			if typeof(returns[2]) ~= "boolean" then
				local addition = _local.typeof(returns[2])

				if typeof(returns[2]) == "string" then
					addition = returns[2]
				end

				return false, "[sort] [1][" .. tostring(i) .. `] function did not return a boolean, function returned: ({args[2]} {v1} {v2}): '{addition}'`
			end

			if returns[2] == true then
				local temp = toSortList[i]
				toSortList[i] = toSortList[j]
				toSortList[j] = temp
			end
		end
	end

	for i, v in ipairs(toSortList) do
		table.insert(sortedList, v)
	end

	return true, sortedList
end
refs["empty?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" and typeof(args[1]) ~= "string" then
		return false, "[empty] expected a list or a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, (#args[1] == 0)
end
refs["range"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[range] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local list = {}
	for index = 1, args[1] do
		table.insert(list, index)
	end

	return true, _local.tableToString(list)
end
refs["rpick"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" and typeof(args[1]) ~= "string" then
		return false, "[pick] expected a list or a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local main = args[1]
	local r = nil
	if typeof(main) == "table" then
		local pick = main[math.random(1, #main)]

		if typeof(pick) == "table" then
			r = _local.tableToString(pick)
		else
			r = pick
		end
	else
		local random = math.random(1, #main)
		r = string.sub(main, random, random)
	end

	return true, r
end
refs["list"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local list = {}
	for i, v in args do
		table.insert(list, v)
	end

	return true, _local.tableToString(list)
end
refs["listclr"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" then
		return false, "[listclr] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	table.clear(args[1])
	return true, _local.tableToString(args[1])
end
refs["alphabet"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local alphabet = {
		"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
	}

	if args[1] and typeof(args[1]) ~= "number" then
		return false, "expected a number but received '" .. _local.typeof(args[1]) .. "'"
	end

	local alphass = {}
	local times = args[1]

	if not args[1] then
		times = #alphabet
	elseif args[1] > #alphabet then
		times = #alphabet
	elseif args[1] < 0 then
		times = 0
	end

	for i = 1, times do
		table.insert(alphass, alphabet[i])
	end

	return true, _local.tableToString(alphass)
end
refs["exists?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local toReadFile, file = _local.getPath(args[1], utils)

	if toReadFile == false then
		return true, nil
	else
		if file:IsA("ValueBase") then
			return true, "file"
		elseif file:IsA("Folder") then
			return true, "directory"
		else
			return true, "unknown"
		end
	end
end
refs["read"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if not args[1] then
		return false, "[read] name is required."
	end
	local toReadFile, file = _local.getPath(args[1], utils)
	if toReadFile == false or not file:IsA("ValueBase") then
		return false, "[read] file not found." 
	end

	return true, file.Value, true
end
refs["readdir"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	args[2] = args[2] or 1
	if not args[1] then
		return false, "[readdir] name is required."
	end

	local toReadDir, file = _local.getPath(args[1], utils)
	if toReadDir == false or not file:IsA("Folder") then
		return false, "[readdir] directory not found."
	end

	local dirs = {}
	local files = {}

	for i, child: Instance in pairs(file:GetChildren()) do
		if child:IsA("Folder") then
			if args[2] >= 2 then
				table.insert(dirs, child.Name)
			else
				table.insert(dirs, child.Name .. "/")
				--table.insert(dirs, '<font color="#4992ff">' .. child.Name .. "/</font>")
			end
		elseif child:IsA("StringValue") then
			table.insert(files, tostring(child.Name))
		end
	end

	local toGo = {}

	for i, v in dirs do
		table.insert(toGo, "_!str!_-" .. _local.stringToHex(tostring(v)))
	end
	for i, v in files do
		table.insert(toGo, "_!str!_-" .. _local.stringToHex(tostring(v)))
	end

	return true, toGo
end
refs["edit"] = function(args, utils)
	local filePath = _local.resolveSpecificArgs(table.remove(args, 1), utils)
	if typeof(filePath) == "table" and filePath[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[write] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if not filePath or not args[1] then
		return false, "[write] name and content is required. received (both args): [1]: " .. _local.typeof(filePath) .. " [2]: " .. _local.typeof(args[1])
	end
	for _, char in  types.ilegalChars do
		if char ~= "" and string.find(filePath, char) then
			return false, `[write] file name cannot contain special characters: "{char}"`
		end
	end
	local toReadFile, file = _local.getPath(filePath, utils)
	if toReadFile == false or not file:IsA("Folder") then
		return false, "[write] file not found."
	end
	if args[1] then
		file.Value = tostring(_local.concat(args, " "))
	end

	return true
end
refs["getpath"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[getpath] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local toReadFile, fileInstance = _local.getPath(args[1], utils)
	if toReadFile == false then
		return false, "[getpath] file doesn't exists." 
	end

	return true, _local.getFullPath(fileInstance)
end
refs["edit"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[mkfile] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if not typeof(args[2]) then
		return false, "[mkfile] expected any value but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local toReadFile, fileInstance = _local.getPath(args[1], utils)
	if toReadFile == false then
		return false, "[edit] file doesn't exists." 
	end

	if args[2] then
		if typeof(args[2]) == "table" then
			args[2] = _local.tableToString(args[2])
		end

		fileInstance.Value = tostring(args[2])
	end

	return true, _local.getFullPath(fileInstance)
end
refs["mkfile"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[mkfile] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if typeof(args[2]) ~= "string" then
		return false, "[mkfile] expected a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	if not args[3] then
		return false, "[mkfile] expected any value but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end

	for _, char in  types.ilegalChars do
		if char ~= "" and string.find(args[2], char) then
			return false, `[mkfile] file name cannot contain special characters: "{char}"`
		end
	end

	local toReadFile, fileInstance = _local.getPath(args[1] .. "/" .. args[2], utils)
	local toReadDir, parentFolderInstance = _local.getPath(args[1], utils)
	if toReadDir == false then
		return false, "[mkfile] file directory doesn't exists." 
	end
	if toReadFile == true then
		return false, "[mkfile] file already exists in '" .. _local.getFullPath(fileInstance) .. "'"
	end

	if not parentFolderInstance:IsA("Folder") then
		return false, "[mkfile] the given path isn't a valid folder.";
	end

	local file = Instance.new("StringValue", parentFolderInstance)
	file.Name = tostring(args[2])

	if args[3] then
		if typeof(args[3]) == "table" then
			args[3] = _local.tableToString(args[3])
		end

		file.Value = tostring(args[3])
	end

	return true, _local.getFullPath(file)
end
refs["mkdir"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[mkdir] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if typeof(args[2]) ~= "string" then
		return false, "[mkdir] expected a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	for _, char in  types.ilegalChars do
		if char ~= "" and string.find(args[2], char) then
			return false, `[mkfile] file name cannot contain special characters: "{char}"`
		end
	end

	local toReadDir, dirInstance = _local.getPath(args[1] .. "/" .. args[2], utils)
	local toReadParentDir, parentFolderInstance = _local.getPath(args[1], utils)
	if toReadParentDir == false then
		return false, "[mkdir] file directory doesn't exists." 
	end
	if toReadDir == true then
		return false, "[mkdir] file already exists in '" .. _local.getFullPath(dirInstance) .. "'"
	end

	if not parentFolderInstance:IsA("Folder") then
		return false, "[mkdir] the given path isn't a valid folder.";
	end

	local folder = Instance.new("Folder", parentFolderInstance)
	folder.Name = tostring(args[2])
	return true, _local.getFullPath(folder)
end
refs["delete"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[delete] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if not args[1] then
		return false, "[delete] name is required."
	end

	local toReadFile, file = _local.getPath(args[1], utils)
	if toReadFile == false then
		return false, "[delete] file or directory doesn't exists." 
	end

	if file:IsA("ValueBase") or file:IsA("Folder") then
		if file == ReplicatedStorage.root then
			return false, "[delete] access denied, unable to delete root." 
		end
		local destroyingOnce: RBXScriptConnection
		destroyingOnce = file.Destroying:Once(function()
			warn("destroyed folder or his parents, cd setted to root.")
			values.cd.Value = ReplicatedStorage.root
		end)
		file:Destroy()
		spawn(function()
			wait(3)
			if destroyingOnce then
				destroyingOnce:Disconnect()
			end
		end)
	else
		return false, "[delete][failed] unknown file type." 
	end

	return true
end
refs["cd"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if args[1] and typeof(args[1]) ~= "string" then
		return false, "[cd] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if args[1] then
		local toReadFile, file = _local.getPath(args[1], utils)
		if toReadFile == false or not file:IsA("Folder") then
			return false, "[cd] directory not found."
		end
		values.cd.Value = file
	end

	return true, values.cd.Value.Name
end
refs["getcd"] = function(args, utils)
	return true, values.cd.Value.Name
end
refs["require"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "string" then
		return false, "[require] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if args[2] and typeof(args[2]) == "boolean" and not args[3] then
		args[3] = args[2]
	elseif args[2] and typeof(args[2]) ~= "table" then
		return false, "[require] expected a list but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	if args[3] and typeof(args[3]) ~= "boolean" then
		return false, "[require] expected a boolean but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end

	local toReadFile, file = _local.getPath(args[1], utils)
	if toReadFile == false or not file:IsA("ValueBase") then
		return false, "[require] path is not a valid file: '" .. tostring(args[1]) .. "'"
	end

	local s, r = require(p.index):run(file.Value, args[2], utils.console, (args[3] or false))

	if s and typeof(s) == "table" and s[1] == false then
		return false, s[2]
	end

	return true, s[2]
end
refs["delay"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[delay] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local number = tonumber(args[1])
	if number ~= nil then
		task.wait(args[1])
	end
	return true
end
refs["max"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local all_numbers = {}
	local lastBigger = 0

	for i, v in args do
		if typeof(v) == "table" then
			for _i, _v in pairs(v) do
				if typeof(_v) ~= "number" then
					return false, "[max] expected a number but received [" .. tostring(i) .. "][" .. tostring(_i) .. "]: '" .. _local.typeof(_v) .. "'"
				end
				table.insert(all_numbers, _v)
			end
		elseif typeof(v) == "number" then
			table.insert(all_numbers, v)
		else
			return false, "[max] expected a number or a list but received [" .. tostring(i) .. "]: '" .. _local.typeof(v) .. "'"
		end
	end

	for __i, number in all_numbers do
		if number > lastBigger then
			lastBigger = number
		end
	end

	return true, lastBigger
end
refs["min"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local all_numbers = {}
	local lastSmaller = 0

	for i, v in args do
		if typeof(v) == "table" then
			for _i, _v in pairs(v) do
				if typeof(_v) ~= "number" then
					return false, "[min] expected a number but received [" .. tostring(i) .. "][" .. tostring(_i) .. "]:'" .. _local.typeof(_v) .. "'"
				end
				table.insert(all_numbers, _v)
			end
		elseif typeof(v) == "number" then
			table.insert(all_numbers, v)
		else
			return false, "[min] expected a number or a list but received [" .. tostring(i) .. "]: '" .. _local.typeof(v) .. "'"
		end
	end

	for __i, number in all_numbers do
		if number < lastSmaller then
			lastSmaller = number
		end
	end

	return true, lastSmaller
end
refs["neg"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[neg] expected a number but received [1]:'" .. _local.typeof(args[1]) .. "'"
	end

	return true, -args[1]
end
refs["+"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	print(args)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[+] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local r = 0
	local success, result, msg = pcall(function()
		for i, v in pairs(args) do
			if typeof(v) ~= "number" then
				return false, "expected a number but received [" .. tostring(i) .. "]:'" .. _local.typeof(v) .. "'"
			end
			r += tonumber(v)
		end
		return true
	end)
	if not success then return {false, msg or "something unexpected happened during the sum."} end
	return true, r
end
refs["-"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local r = table.remove(args, 1)
	if typeof(r) ~= "number" then
		return false, "[-] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		for i, v in pairs(args) do
			if typeof(v) ~= "number" then
				return false, "[-] expected a number but received [" .. tostring(i) .. "]:'" .. _local.typeof(v) .. "'"
			end
			r -= tonumber(v)
		end
		return true
	end)
	if not success then return {false, msg or "something unexpected happened during the sub"} end
	return true, r
end
refs["*"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local r = table.remove(args, 1)
	if typeof(r) ~= "number" then
		return false, "[*] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		for i, v in pairs(args) do
			if typeof(v) ~= "number" then
				return false, "[*] expected a number but received [" .. tostring(i) .. "]:'" .. _local.typeof(v) .. "'"
			end
			r *= tonumber(v)
		end
		return true
	end)
	if not success then return {false, msg or "something unexpected happened during the mul"} end
	return true, r
end
refs["^"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[^] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[1]) ~= "number" then
		return false, "[^] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return args[1] ^ args[2]
	end)
	if not success then return {false, msg or "something unexpected happened during the expo"} end
	return true, result
end
refs["**"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[**] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return args[1] ^ 2
	end)
	if not success then return {false, msg or "something unexpected happened during the square expo"} end
	return true, result
end
refs["***"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[***] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return args[1] ^ 3
	end)
	if not success then return {false, msg or "something unexpected happened during the cubic expo"} end
	return true, result
end
refs["/"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[/] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[/] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return args[1] / args[2]
	end)
	if not success then return {false, msg or "something unexpected happened during the div"} end
	return true, result
end
refs["//"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[//] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[//] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return args[1] // args[2]
	end)
	if not success then return {false, msg or "something unexpected happened during the floor div"} end
	return true, result
end
refs["%"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[%] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[%] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return args[1] % args[2]
	end)
	if not success then return {false, msg or "something unexpected happened during the mod div"} end
	return true, result
end
refs["lorem"] = function(args, utils)
	return true, "Lorem ipsum dolor sit, amet consectetur adipisicing elit. Laborum, quas! Illum blanditiis, sed, earum vitae in laboriosam sint neque vero quos animi sunt nesciunt repudiandae qui? Voluptate possimus natus optio."
end
refs["tick"] = function(args, utils)
	return true, tick()
end
refs["date"] = function(args, utils)
	return true, string.split(os.date("%d/%m/%Y", os.time()), "/")
end
refs["time"] = function(args, utils)
	return true, string.split(os.date("%H:%M:%S", os.time()), ":")
end
refs["random"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[random] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[random] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.random(args[1], args[2])
	end)
	if not success then return {false, msg or "something unexpected happened during the random"} end
	return true, result
end
refs["clamp"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[clamp] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[clamp] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	if typeof(args[3]) ~= "number" then
		return false, "[clamp] expected a number but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.clamp(args[1], args[2], args[3])
	end)
	if not success then return {false, msg or "something unexpected happened during the clamp"} end
	return true, result
end
refs["lerp"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[lerp] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[lerp] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	if typeof(args[3]) ~= "number" then
		return false, "[lerp] expected a number but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end
	local success, result, msg = pcall(function()
		return _local.lerp(args[1], args[2], args[3])
	end)
	if not success then return {false, msg or "something unexpected happened during the lerp"} end
	return true, result
end
refs["round"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[round] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if args[2] and typeof(args[2]) ~= "number" then
		return false, "[round] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.round(args[1] * (args[2] or 1))
	end)
	if not success then return {false, msg or "something unexpected happened during the round"} end
	return true, result
end
refs["floor"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[floor] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.floor(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the floor"} end
	return true, result
end
refs["abs"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[abs] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.abs(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the abs"} end
	return true, result
end
refs["sin"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[sin] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.sin(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the sin"} end
	return true, result
end
refs["cos"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[cos] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.cos(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the cos"} end
	return true, result
end
refs["sinh"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[sinh] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.sinh(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the sinh"} end
	return true, result
end
refs["cosh"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[cosh] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.cosh(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the cosh"} end
	return true, result
end
refs["acos"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[acos] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.acos(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the acos"} end
	return true, result
end
refs["asin"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[asin] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.asin(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the asin"} end
	return true, result
end
refs["atan"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[atan] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.atan(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the atan"} end
	return true, result
end
refs["atan2"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[atan] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "number" then
		return false, "[atan] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.atan2(args[1], args[2])
	end)
	if not success then return {false, msg or "something unexpected happened during the atan2"} end
	return true, result
end

refs["ceil"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[ceil] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.ceil(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the ceil"} end
	return true, result
end
refs["log10"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[log10] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.log10(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the log10"} end
	return true, result
end
refs["randomseed"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[randomseed] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.randomseed(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the randomseed"} end
	return true, result
end
refs["deg"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[deg] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.deg(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the deg"} end
	return true, result
end
refs["sqrt"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[sqrt] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.sqrt(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the sqrt"} end
	return true, result
end
refs["tan"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[tan] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.tan(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the tan"} end
	return true, result
end
refs["rad"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[rad] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.rad(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the rad"} end
	return true, result
end
refs["log"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[log] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[1]) ~= "number" then
		return false, "[log] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.log(args[1], args[2])
	end)
	if not success then return {false, msg or "something unexpected happened during the log"} end
	return true, result
end
refs["noise"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[noise] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[1]) ~= "number" then
		return false, "[noise] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	if typeof(args[1]) ~= "number" then
		return false, "[noise] expected a number but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.noise(args[1], args[2], args[3])
	end)
	if not success then return {false, msg or "something unexpected happened during the noise"} end
	return true, result
end
refs["sign"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "number" then
		return false, "[sign] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if args[1] == 0 then
		return true, 0
	elseif args[1] > 0 then
		return true, 1
	else
		return true, -1
	end
end
refs["inv"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local numbers = {}

	for i, v in args do
		if typeof(v) ~= "number" then
			return false, "[inv] expected a number but received [".. tostring(i) .."]: '" .. _local.typeof(v) .. "'"
		end

		numbers[i] = v * -1
	end

	return true, numbers
end
refs["e"] = function(args, utils)
	return true, 2.71828
end
refs["json-encode"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local success, result, msg = pcall(function()
		return game:GetService("HttpService"):JSONEncode(args[1])
	end)
	if not success then return false, msg or "encode error." end
	return true, result
end
refs["json-decode"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	
	local success, result, msg = pcall(function()
		return jsonObjToTable(args[1])
	end)
	if not success then return false, msg or "decode error." end
	return true, result
end
refs["http-get"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "string" then
		return false, "[http-get] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if string.sub(args[1], 0, 7) ~= "http://" and string.sub(args[1], 0, 8) ~= "https://" then
		return false, "[http-get] expected a valid url, expected http:// or https://, received [1]: '" .. args[1] .. "'"
	end
	local success, result, msg = ReplicatedStorage.remotes.http.get:InvokeServer(args[1])
	if not success then return false, msg or result or "[http-get] http get error." end
	return true, result
end
refs["http-post"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if typeof(args[1]) ~= "string" then
		return false, "[http-post] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if string.sub(args[1], 1, 7) ~= "http://" and string.sub(args[1], 1, 8) ~= "https://" then
		return false, "[http-post] expected a valid url, expected http:// or https://, received [1]: '" .. args[1] .. "'"
	end

	local success, result = ReplicatedStorage.remotes.http.post:InvokeServer(args[1], (args[2] or {}), false)

	if not success then return false, result end
	return true, result
end
refs["object"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if #args % 2 ~= 0 then
		return false, "[object] expected a pair for each arguments, received " .. tostring(#args) .. ", expected " .. tostring(#args+1) .. " or " .. tostring(#args-1) .. "."
	end

	local result = {}
	local run = 0
	for i = 1, #args, 2 do
		run += 1
		local indexName = args[i]
		local valueData = args[i+1]

		if typeof(indexName) ~= "string" then
			return false, "[object] expected a string for index names but received [" .. tostring(run+1) .. "]:'" .. _local.typeof(indexName) .. "'"
		end

		result[indexName] = valueData
	end
	return true, result
end
refs["version"] = function(args, utils)
	return true, language.version
end
refs["odd?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[odd] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, args[1] % 2 == 0
end
refs["even?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "number" then
		return false, "[even] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, args[1] % 2 ~= 0
end
refs["bool?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, typeof(args[1]) == "boolean"
end
refs["num?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, typeof(args[1]) == "number"
end
refs["str?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, typeof(args[1]) == "string"
end
refs["list?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, typeof(args[1]) == "table"
end
refs["filter"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if typeof(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if typeof(args[1]) ~= "table" then
		return false, "[filter] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if typeof(args[2]) ~= "string" then
		return false, "[filter] expected a function name as a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local togo;
	if typeof(args[1]) == "table" then
		togo = {}
		for i, v in args[1] do
			if typeof(v) == "table" then
				v = _local.tableToString(v)
			end
			local returns = require(p.index):run(`({args[2]} {v})`, nil, utils.console, true)

			if returns[1] == false then
				return false, "[filter] [2] function: "  .. (returns[2] or "")
			end
			if typeof(returns[2]) ~= "boolean" then
				local addition = _local.typeof(returns[2])

				if typeof(returns[2]) == "string" then
					addition = returns[2]
				end

				return false, "[filter] [1][" .. tostring(i) .. `] function did not return a boolean, function returned: ({args[2]} {v}): '{addition}'`
			end

			if returns[2] == true then
				table.insert(togo, v)
			end
		end
	end

	return true, togo
end

return refs