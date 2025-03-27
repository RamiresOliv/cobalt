local json = require("modules.dkjson")
local fs = require("src.filesystem")

local memory = {
    global = {
        values = {
            cd = { Value = "root" }  -- idk
        }
    },
    root = { 
        Name = "root", 
        Parent = nil, 
        Children = {}  -- idkddddddddddd
    }
}
local temporary = {
    paths = {
      http = "temporary/http",
      functions = "temporary/functions",
      values = "temporary/values"
    }
}

local _local = {}
_local.wait = function(n)
    local t0 = os.clock()
    while os.clock() - t0 <= n do end
end
_local.lerp = function(a, b, t)
    return a + (b - a) * t
end
_local.concat = function(list, separator)
    for i, v in pairs(list) do
        list[i] = tostring(v)
    end
    return table.concat(list, separator or " ")
end
_local.typeof = function(thing)
    local t = type(thing)
    if t == "table" then t = "list" end
    return t
end
_local.stringToHex = function(str)
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end
_local.hexToString = function(str)
    return (str:gsub('..', function(c)
        return string.char(tonumber(c, 16))
    end))
end


_local.getPath = function(dir, utils) -- to rework
    if dir == "root" then
        return true, memory.root
    end
    local parts = {}
    for part in string.gmatch(dir, "[^/]+") do
        table.insert(parts, part)
    end
    local current = memory.root
    for i = 2, #parts do
        current = fs.check(current.Children or {}, parts[i])
        if not current then return false, "path not found" end
    end
    return true, current
end

_local.getFullPath = function(instance, utils) -- to rework
    local path = instance.Name
    local current = instance.Parent
    while current do
        path = current.Name .. "/" .. path
        current = current.Parent
    end
    return path
end

_local.tableToString = function(list)
    if _local.typeof(list) ~= "list" then return nil end
    local dat = "["
    for i, v in ipairs(list) do
        if _local.typeof(v) == "list" then
            v = _local.tableToString(v)
        end
        dat = dat .. tostring(v)
        if i < #list then dat = dat .. ", " end
    end
    dat = dat .. "]"
    return dat
end

----------------------------------------
-- Função para converter JSON em tabela (recursivamente)
local function jsonObjToTable(json_obj)
    local v = json.decode(json_obj)
    local function convertTable(t)
        local result = {}
        for _, value in pairs(t) do
            if _local.typeof(value) == "list" then
                table.insert(result, convertTable(value))
            else
                table.insert(result, value)
            end
        end
        return result
    end
    if _local.typeof(v) == "list" then
        return convertTable(v)
    else
        return v
    end
end

----------------------------------------
-- Função resolve_args – responsável por processar argumentos
local function resolve_args(v, utils, allowSpecificReturns)
    local function remove_outer_quotes(s)
        if s:sub(1, 1) == '"' and s:sub(-1) == '"' then
            return s:sub(2, -2)
        else
            return s
        end
    end

    if _local.typeof(v) == "string" then
        if string.sub(v, 1, 8) == "_!str!_-" then
            local hex = string.sub(v, 9)
            local str = _local.hexToString(hex)
            v = str
        elseif string.sub(v, 1, 8) == "_!fmt!_-" then
            v = string.sub(v, 9)
        end
    end

    if v == "true" then
        v = true
    elseif v == "false" then
        v = false
    elseif v == "nil" then
        v = nil
    end

    if _local.typeof(v) == "string" then
        -- Substituição de variáveis temporárias (simulando temporary.values)
        for _, file in ipairs(fs.list(temporary.paths.values)) do
            local filePath = temporary.paths.values .. "/" .. file
            local togoV = fs.read(filePath)
            if togoV == "true" then
                togoV = true
            elseif togoV == "false" then
                togoV = false
            elseif togoV == "nil" then
                togoV = nil
            end
            local ok, n = pcall(function() return tonumber(tostring(togoV)) end)
            local togo = tostring(togoV)
            if string.find(tostring(togoV), " ") then
                togo = '"' .. tostring(togoV) .. '"'
            end
            if ok and n ~= nil then
                togo = tostring(n)
            end
            if _local.typeof(togoV) == "boolean" then
                togo = tostring(togoV)
            elseif _local.typeof(togoV) == "string" and string.sub(togoV, 1, 1) == "[" and string.sub(togoV, -1) == "]" then
                togo = togoV
            end
            local final = togo
            if string.sub(tostring(togoV), 1, 1) == "{" and string.sub(tostring(togoV), -1) == "}" then
                final = '"' .. string.gsub(togoV, '"', "_$#@¨COMMA_CHAR¨@#$_") .. '"'
            end
            final = final:gsub("%%", "#")
            v = v:gsub("{" .. file .. "}", final)
        end
        local constants = require("src.constants")()  -- módulo de constantes
        if _local.typeof(v) == "string" then
            for i_, v_ in pairs(constants) do
                v = v:gsub("{" .. tostring(i_) .. "}", tostring(v_))
            end
        end
    end

    local thingToReturn = nil
    if _local.typeof(v) == "string" and v:sub(1, 1) == '(' and v:sub(-1) == ')' then
        local compilation = require("src.index"):run(v, nil, true)
        thingToReturn = compilation[4]
        if compilation[1] == false then
            if _local.typeof(compilation[2]) == "list" then
                return {false, "[sub-function]: " .. compilation[2][2]}
            else
                return {false, "[sub-function]: " .. compilation[2]}
            end
        end
        if compilation[3] ~= true then
            if _local.typeof(compilation[2]) == "list" then
                local a = _local.resolveArgs(compilation[2], utils)
                compilation[2] = a
            else
                compilation[2] = _local.resolveSpecificArgs(compilation[2], utils, allowSpecificReturns)
            end
        end
        if compilation[1] == "_!!dDecodePSCFail!!_" then
            return false, compilation[2]
        end
        v = compilation[2]
    elseif _local.typeof(v) == "string" and v:sub(1, 1) == '[' and v:sub(-1) == ']' then

        v = v:sub(2, -2)
        local function split_ignoring_quotes_and_brackets(str)
            local result = {}
            local current = ""
            local inside_quote = false
            local bracket_level = 0
            for i = 1, #str do
                local char = str:sub(i, i)
                if char == '"' then
                    inside_quote = not inside_quote
                    current = current .. char
                elseif not inside_quote then
                    if char == '[' then
                        bracket_level = bracket_level + 1
                        current = current .. char
                    elseif char == ']' then
                        bracket_level = bracket_level - 1
                        current = current .. char
                    elseif char == ',' and bracket_level == 0 then
                        table.insert(result, current)
                        current = ""
                    else
                        current = current .. char
                    end
                else
                    current = current .. char
                end
            end
            if current ~= "" then table.insert(result, current) end
            return result
        end

        local parts = split_ignoring_quotes_and_brackets(v)
        local rendered_table = {}
        for _, value in ipairs(parts) do
            value = value:match("^%s*(.-)%s*$")
            value = remove_outer_quotes(value)
            local dec = _local.resolveSpecificArgs(value, utils)
            if _local.typeof(dec) == "list" and dec[1] == false then 
                return {false, dec[2]}
            end
            table.insert(rendered_table, dec)
        end

        local result = {}
        local stack = { result }
        local currentTable = result
        for _, value in ipairs(rendered_table) do
            if _local.typeof(value) == "string" and value:sub(1, 1) == '[' and value:sub(-1) == ']' then
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
                    local rSA = _local.resolveSpecificArgs(require("arguments"):indexArgHandler(cleanValue), utils)
                    if _local.typeof(rSA) == "list" and rSA[1] == "_!!dDecodePSCFail!!_" then 
                        return {false, "[sub-function]: " .. tostring(rSA[2])}
                    end
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
        if _local.typeof(v) == "string" then
            if v == "_-!@!_-!-continue-skip-this-thing-rn!" or v == "_-!@!_-!-break-and-stop-rn!" then
                v = nil
            end
        end
    end

    if _local.typeof(v) == "string" then
        v = string.gsub(v, "_$#@¨COMMA_CHAR¨@#$_", '"')
    end

    local ok, n = pcall(function() return tonumber(v) end)
    if ok and n ~= nil then v = n end

    return {true, v}, thingToReturn
end

_local.resolveArgs = function(args, utils)
    for i, v in ipairs(args) do
        local dec = resolve_args(v, utils, false)
        if dec[1] == false then return {"_!!dDecodePSCFail!!_", dec[2]} end
        args[i] = dec[2]
    end
    return args
end

_local.resolveSpecificArgs = function(args, utils, allowSpecificReturns)
    local dec, ohgod = resolve_args(args, utils, (allowSpecificReturns or false))
    if dec[1] == false then return {"_!!dDecodePSCFail!!_", dec[2]} end
    return dec[2], ohgod
end

----------------------------------------
-- Tabela de Referências (refs)
local refs = { _self = {} }

refs._self.refs_size = function()
    local size = 0
    for _ in pairs(refs) do
        size = size + 1
    end
    return size - 1
end

refs["var"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if not args[1] or _local.typeof(args[1]) ~= "string" then
        return false, "[var] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end

    --[[
    local ffc = fs.check(memory.temporary.values, tostring(args[1]))
    if ffc then
        ffc.Value = (_local.typeof(args[2]) == "list" and json.encode(args[2]) or tostring(args[2]))
    else
        local variable = { Name = tostring(args[1]), Value = nil, Type = "StringValue" }
        table.insert(memory.temporary.values, variable)
        if _local.typeof(args[2]) == "list" then
            variable.Value = json.encode(args[2])
        else
            variable.Value = tostring(args[2])
        end
    end]]

    -- Define the folder path where functions are stored as files
	local folderPath = "temporary/values"  -- This folder must exist in your file system
	local filePath = folderPath .. "/" .. tostring(args[1])

    local content = "unknown?"
    if _local.typeof(args[2]) == "list" then
        content = json.encode(args[2])
    else
        content = tostring(args[2])
    end

	local file = io.open(filePath, "w")
	if file then
		file:write(content)
		file:close()
		return true
	else
		return false, "Unable to write function-file: " .. filePath
	end
end
refs["prompt"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if not args[1] then
		args[1] = "script is asking something"
	end

	local answer = nil

    io.write(tostring(args[1]) .. " ")
    answer = io.read()

	local r = _local.stringToHex(answer)
	return true, "_!str!_-" .. tostring(r)
end
refs["pairs"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "list" then
        return false, "[pairs] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local togo = {}
    for i, v in pairs(args[1]) do
        togo[i] = v
    end
    return true, togo
end

refs["ipairs"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "list" then
        return false, "[ipairs] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local togo = {}
    for i, v in ipairs(args[1]) do
        togo[i] = v
    end
    return true, togo
end
refs["run"] = function(args, utils)
	local s, a = require("src.index"):run(table.concat(args, " "), nil, true)
	return true, {s[1], a or s[2] or nil}
end
refs["spawn"] = function(args, utils)
	if not type(args[1]) then
		return false, "[spawn] expected a any value but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

    local co = coroutine.create(function()
		require("src.index"):run(table.concat(args, " "), nil, true)
	end)
    coroutine.resume(co)

	return true
end
refs["get"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if not args[1] or _local.typeof(args[1]) ~= "string" then
        return false, "[get] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local ffc = fs.check(temporary.values, tostring(args[1]))
    local val = nil
    if ffc then
        val = ffc.Value
    end
    return true, val
end

refs["print"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    for i, v in ipairs(args) do
        local go = "undefined"
        local t = _local.typeof(v)
        if t == "string" then
            if v == "_-!@!_-!-continue-skip-this-thing-rn!" or v == "_-!@!_-!-break-and-stop-rn!" then
                go = ""
            else
                if string.sub(v, 1, 1) == '"' and string.sub(v, -1) == '"' then
                    go = string.sub(v, 2, -2)
                else
                    go = tostring(v)
                end
            end
        elseif t == "number" or t == "boolean" then
            go = tostring(v)
        elseif t == "list" then
            local function readTable(t)
                local togo = "["
                if #t == 0 then
                    togo = togo .. "]"
                else
                    for i, v in ipairs(t) do
                        if _local.typeof(v) == "list" then
                            if i == #t then
                                togo = togo .. readTable(v) .. "]"
                            else
                                togo = togo .. readTable(v) .. ", "
                            end
                        else
                            local valueConversion = function(rawValue)
                                if _local.typeof(rawValue) == "string" then
                                    return '"' .. tostring(rawValue) .. '"'
                                else
                                    return tostring(rawValue)
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
        --print(type(go))
        print(go)
    end
    return true
end

refs["println"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    local toPrint = {}
    for i, v in ipairs(args) do
        local go = "undefined"
        local t = _local.typeof(v)
        if t == "string" then
            if v == "_-!@!_-!-continue-skip-this-thing-rn!" or v == "_-!@!_-!-break-and-stop-rn!" then
                go = ""
            else
                go = tostring(v)
            end
        elseif t == "number" or t == "boolean" then
            go = tostring(v)
        elseif t == "list" then
            local function readTable(t)
                local togo = "["
                if #t == 0 then
                    togo = togo .. "]"
                else
                    for i, v in ipairs(t) do
                        if _local.typeof(v) == "list" then
                            if i == #t then
                                togo = togo .. readTable(v) .. "]"
                            else
                                togo = togo .. readTable(v) .. ", "
                            end
                        else
                            local valueConversion = function(rawValue)
                                if _local.typeof(rawValue) == "string" then
                                    return '"' .. tostring(rawValue) .. '"'
                                else
                                    return tostring(rawValue)
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
    print(table.concat(toPrint, " "))
    return true
end

refs["clear"] = function(args, utils)
    -- Em ambiente de console, clear pode ser simulado imprimindo uma separação
    os.execute("cls")
    return true
end

refs["for"] = function(args, utils)
    local operator = _local.resolveSpecificArgs(table.remove(args, 1), utils)
    if _local.typeof(operator) == "list" and operator[1] == "_!!dDecodePSCFail!!_" then 
        return false, operator[2] 
    end
    local loopArgs = {}
    local commands = {}
    for i, v in pairs(args) do
        if _local.typeof(v) == "string" then
            if v:sub(1, 1) == '(' and v:sub(-1) == ')' then
                table.insert(commands, v)
            else
                table.insert(loopArgs, v)
            end
        end
    end
    local function loopa(i, v)
        for _, c in ipairs(commands) do
            local translated_v, r = _local.resolveSpecificArgs(v, utils, true)
            c = c:gsub("{" .. (loopArgs[1] or "_index") .. "}", tostring(i))
            if type(translated_v) == "table" then
                translated_v = _local.tableToString(translated_v)
            end
            c = c:gsub("{" .. (loopArgs[2] or "_value") .. "}", tostring(translated_v))
            local r, returns = require("src.index"):run(c, nil, true)
            if r[1] == false then 
                return false, "[for] function error [" .. tostring(i) .. "]: " .. r[2] 
            end
            if r[2] and _local.typeof(r[2]) == "string" and string.sub(r[2], 1, 9) == "_-!@!_-!-" then
                return true, returns or r[2]
            end
        end
    end
    if _local.typeof(operator) == "list" then
        for index, value in ipairs(operator) do
            local a, b = loopa(index, value)
            if a ~= nil then
                if b == "_-!@!_-!-continue-skip-this-thing-rn!" then
                    -- continue
                elseif b == "_-!@!_-!-break-and-stop-rn!" then
                    break
                end
            end
        end
    elseif _local.typeof(operator) == "number" then
        for index = 1, operator do
            local a, b = loopa(index, "nil")
            if a ~= nil then
                if b == "_-!@!_-!-continue-skip-this-thing-rn!" then
                    -- continue
                elseif b == "_-!@!_-!-break-and-stop-rn!" then
                    break
                end
            end
        end
    else
        return false, "[for] expected a number or a list but received [1]: '" .. _local.typeof(operator) .. "'"
    end
    return true
end
refs["function"] = function(rawArgs, utils)
	local func_name = table.remove(rawArgs, 1)
	local argsList = {}
	local cmds = {}

	for i, v in pairs(rawArgs) do
		if type(v) == "string" then
			if v:sub(1, 1) == '(' and v:sub(-1) == ')' then
				table.insert(cmds, v)
			else
				table.insert(argsList, v)
			end
		end
	end

	local folderPath = "temporary/functions"
	local filePath = folderPath .. "/" .. tostring(func_name) .. ".json"

	local data = {
		arguments = argsList,
		commands = cmds
	}

	local jsonData = json.encode(data)
	local file = io.open(filePath, "w")
	if file then
		file:write(jsonData)
		file:close()
		return true
	else
		return false, "Unable to write function-file: " .. filePath
	end
end
refs["if"] = function(args, utils)
    local condition = table.remove(args, 1)
    local elseFound = false
    local true_commands = {}
    local false_commands = {}
    for i, v in pairs(args) do
        if _local.typeof(v) == "string" then
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
    local a = _local.resolveSpecificArgs(condition, utils)
    if a and tostring(a) == "true" then
        for i, v in ipairs(true_commands) do
            local r, ohno = _local.resolveSpecificArgs(v, utils, true)
            if _local.typeof(r) == "list" and r[1] == "_!!dDecodePSCFail!!_" then 
                return false, r[2] 
            end
            if r == "_-!@!_-!-continue-skip-this-thing-rn!" or r == "_-!@!_-!-break-and-stop-rn!" then
                return true, r
            end
            if ohno == true then
                return true, {"_-!@!_-!-return-and-stop-rn!", r}
            end
        end
    else
        for i, v in ipairs(false_commands) do
            local r, ohno = _local.resolveSpecificArgs(v, utils, true)
            if _local.typeof(r) == "list" and r[1] == "_!!dDecodePSCFail!!_" then 
                return false, r[2] 
            end
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
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    local typeofit = _local.typeof(args[1])
    if typeofit == "list" then typeofit = "list" elseif typeofit == "nil" then typeofit = "nil" end
    return true, typeofit
end
refs["true"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

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
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    local togo = {"_-!@!_-!-return-and-stop-rn!"}
    table.insert(togo, args[1])
    return true, togo
end
refs["return-if"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local func = table.remove(args, 1)
	if type(func) ~= "boolean" then
		return false, "[return-if] expected a boolean but received [1]: '" .. _local.typeof(func) .. "'"
	end

	local togo = nil
	if func == true then
		togo = {"_-!@!_-!-return-and-stop-rn!"}
		table.insert(togo, args[1])
	end

    --print(togo[2])
	return true, togo
end
refs["not"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    return true, (not args[1])
end

refs["and"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    local r = true
    for i, v in ipairs(args) do
        local argsReq = _local.resolveSpecificArgs(v, utils)
        if _local.typeof(argsReq) == "list" and argsReq[1] == "_!!dDecodePSCFail!!_" then 
            return {false, args[2]} 
        end
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
    for i, v in ipairs(args) do
        local argsReq = _local.resolveSpecificArgs(v, utils)
        if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
            return false, args[2] 
        end
        if argsReq == true then
            r = true
            break
        end
    end
    return true, r
end

refs["=="] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    return true, (args[1] or nil) == (args[2] or nil)
end

refs["!="] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    return true, (args[1] or "_ITSNIL!!!!!!!!!") ~= (args[2] or "_ITSNIL!!!!!!!!!")
end

refs["nil?"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) == nil or args[1] == nil or not args[1] then
        return true, true
    else
        return true, false
    end
end

refs[">"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[>] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[>] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, r = pcall(function()
        return tonumber(args[1]) > tonumber(args[2])
    end)
    if not ok then 
        return false, "error in try compare: " .. _local.typeof(args[1]) .. " > " .. _local.typeof(args[2])
    end
    return true, r
end

refs["<"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[<] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[<] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, r = pcall(function()
        return tonumber(args[1]) < tonumber(args[2])
    end)
    if not ok then 
        return false, "error in try compare: " .. _local.typeof(args[1]) .. " < " .. _local.typeof(args[2])
    end
    return true, r
end

refs[">="] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[>=] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[>=] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, r = pcall(function()
        return tonumber(args[1]) >= tonumber(args[2])
    end)
    if not ok then 
        return false, "error in try compare: " .. _local.typeof(args[1]) .. " >= " .. _local.typeof(args[2])
    end
    return true, r
end

refs["<="] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[<=] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[<=] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, r = pcall(function()
        return tonumber(args[1]) <= tonumber(args[2])
    end)
    if not ok then 
        return false, "error in try compare: " .. _local.typeof(args[1]) .. " <= " .. _local.typeof(args[2])
    end
    return true, r
end
refs["str"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

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
	-- Define ANSI escape codes for terminal colors and styles
	local colors = {
		red     = "\27[31m",
		green   = "\27[32m",
		blue    = "\27[34m",
		yellow  = "\27[33m",
		purple  = "\27[35m",
		orange  = "\27[91m",  -- bright red/orange
		cyan    = "\27[36m",
		magenta = "\27[95m",
		black   = "\27[30m",
		white   = "\27[37m",
		gray    = "\27[90m",
		pink    = "\27[95m",
		brown   = "\27[33m",  -- reused yellow for brown
		lime    = "\27[32m",
		navy    = "\27[34m",
		blank   = "\27[0m"    -- reset/no color
	}

	-- Resolve arguments using our helper
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then 
		return false, args[2] 
	end

	-- Ensure first two arguments are strings
	args[1] = tostring(args[1])
	args[2] = tostring(args[2])

	if type(args[1]) ~= "string" then
		return false, "[color] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "string" then
		return false, "[color] expected a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	-- Look up the color code using the lowercased color name
	local colorCode = colors[args[2]:lower()]
	if not colorCode then
		local clrs = {}
		for k, _ in pairs(colors) do
			table.insert(clrs, k)
		end
		return false, "[color] invalid color name. Valid names are: " .. table.concat(clrs, ", ") .. "."
	end

	-- Apply formatting: if the second argument is "bold" or "italic", use corresponding ANSI codes;
	-- otherwise, wrap the text in the color code.
	local formatted
	if args[2]:lower() == "bold" then
		formatted = "\27[1m" .. args[1] .. "\27[0m"
	elseif args[2]:lower() == "italic" then
		formatted = "\27[3m" .. args[1] .. "\27[0m"
	else
		formatted = colorCode .. args[1] .. "\27[0m"
	end

	-- Convert the formatted string to a hexadecimal representation and return it prefixed with _!str!_-
	local hex = _local.stringToHex(formatted)
	return true, "_!str!_-" .. tostring(hex)
end
refs["format"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    args[1] = tostring(args[1])
    if _local.typeof(args[1]) ~= "string" then
        return false, "[format] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local arg1 = tostring(table.remove(args, 1))
    for i, v in ipairs(args) do
        arg1 = arg1:gsub("{" .. tostring(i) .. "}", tostring(v))
    end
    local hex = _local.stringToHex(arg1)
    return true, "_!str!_-" .. tostring(hex)
end
refs["split"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	args[1] = tostring(args[1])

	if type(args[1]) ~= "string" then
		return false, "[split] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local list = string.split(args[1], tostring(args[2] or " "))
	return true, _local.tableToString(list)
end
refs["replace"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    args[1] = tostring(args[1])
    if _local.typeof(args[1]) ~= "string" then
        return false, "[replace] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    return true, string.gsub(tostring(args[1]), tostring(args[2]), tostring(args[3]))
end
refs["len"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" and type(args[1]) ~= "table" then
		return false, "[len] expected a string or a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	return true, #args[1]
end
refs["reverse"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "string" and _local.typeof(args[1]) ~= "list" then
        return false, "[reverse] expected a list or a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[1]) == "list" then
        local newTable = {}
        for i, v in ipairs(args[1]) do
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
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    args[1] = tostring(args[1])
    if _local.typeof(args[1]) ~= "string" then
        return false, "[upper] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    return true, string.upper(tostring(args[1]))
end

refs["lower"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    args[1] = tostring(args[1])
    if _local.typeof(args[1]) ~= "string" then
        return false, "[lower] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    return true, string.lower(tostring(args[1]))
end

refs["upper?"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    args[1] = tostring(args[1])
    local found = false
    local alphabet = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
    if _local.typeof(args[1]) ~= "string" then
        return false, "[upper?] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local function splitWords(str)
        local words = {}
        for word in string.gmatch(str, ".") do 
            table.insert(words, word) 
        end
        return words
    end
    for i, v in pairs(splitWords(args[1])) do
        for ai, l in ipairs(alphabet) do
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
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    args[1] = tostring(args[1])
    local found = false
    local alphabet = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
    if _local.typeof(args[1]) ~= "string" then
        return false, "[lower?] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local function splitWords(str)
        local words = {}
        for word in string.gmatch(str, ".") do 
            table.insert(words, word) 
        end
        return words
    end
    for i, v in pairs(splitWords(args[1])) do
        for ai, l in ipairs(alphabet) do
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local list = table.remove(args, 1)

	if type(list) ~= "table" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local list = table.remove(args, 1)

	if type(list) ~= "table" then
		return false, "[listget] expected a list but received [1]: '" .. _local.typeof(list) .. "'"
	end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local list = table.remove(args, 1)

	if type(list) ~= "table" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "table" then
		return false, "[join] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local join = table.concat(args[1], tostring(args[2] or " "))

	return true, join
end
refs["starts?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[starts] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "string" then
		return false, "[starts] expected a list but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	-- args[1]: the string which I want to check if it starts with something.
	-- args[2]: is the thing which I want to check the string if it has.
	return true, (string.sub(args[1], 1, #args[2]) == args[2])
end
refs["ends?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[ends] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "string" then
		return false, "[ends] expected a list but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, (string.sub(args[1], -#args[2], -1) == args[2])
end
refs["skip"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[skip] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "number" then
		return false, "[skip] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, string.sub(args[1], args[2])
end
refs["crop"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[skip] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "number" then
		return false, "[skip] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	if args[3] and type(args[3]) ~= "number" then
		return false, "[skip] expected a number but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end

	return true, string.sub(args[1], args[2], (args[3] or args[2]))
end
refs["first"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[first] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "number" or args[2] < 0 then
		return false, "[first] expected a positive number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, string.sub(args[1], 0, args[2])
end
refs["last"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[last] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "number" or args[2] < 0 then
		return false, "[last] expected a positive number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	return true, string.sub(args[1], -args[2], -1)
end
refs["find"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" and type(args[1]) ~= "table" then
		return false, "[find] expected a string or a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	if type(args[1]) == "string" then
		if type(args[2]) ~= "string" then
			return false, "[find] expected a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
		end

		return true, string.find(args[1], args[2]) ~= nil
	else
		if type(args[1]) ~= "string" and type(args[1]) ~= "number" then
			return false, "[find] expected a string or a list or a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
		end

		return true, table.find(args[1], args[2]) ~= nil
	end
end
refs["sort"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "table" then
		return false, "[sort] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "string" then
		return false, "[sort] expected a function name as a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local toSortList = args[1]
	local sortedList = {}
	-- [1,3,2]: [1,2,3]
	-- local returns = require("src.index"):run(`({args[2]} {v} {args[1][i+1]})`, nil, true)

	for i = 1, #toSortList - 1 do
		for j = i + 1, #toSortList do
			local v1 = toSortList[i]
			local v2 = toSortList[j]

			if type(v1) == "table" then
				v1 = _local.tableToString(v1)
			end
			if type(v2) == "table" then
				v2 = _local.tableToString(v2)
			end
			local returns = require("src.index"):run("(" ..  args[2] .. " " .. v1 .. " " .. v2 .. ")", nil, true)

			if returns[1] == false then
				return false, "[sort] [2] function: "  .. (returns[2] or "")
			end
			if type(returns[2]) ~= "boolean" then
				local addition = _local.typeof(returns[2])

				if type(returns[2]) == "string" then
					addition = returns[2]
				end

				return false, "[sort] [1][" .. tostring(i) .. "] function did not return a boolean, function returned: (" ..  args[2] .. " " .. v1 .. " " .. v2 .. "): " .. addition
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "table" and type(args[1]) ~= "string" then
		return false, "[empty] expected a list or a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, (#args[1] == 0)
end
refs["range"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "table" and type(args[1]) ~= "string" then
		return false, "[pick] expected a list or a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	local main = args[1]
	local r = nil
	if type(main) == "table" then
		local pick = main[math.random(1, #main)]

		if type(pick) == "table" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local list = {}
	for i, v in args do
		table.insert(list, v)
	end

	return true, _local.tableToString(list)
end
refs["listclr"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "table" then
		return false, "[listclr] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	args[1] = {}
	return true, _local.tableToString(args[1])
end

-- here to do the FS"

refs["alphabet"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    local alphabet = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
    if args[1] and _local.typeof(args[1]) ~= "number" then
        return false, "[alphabet] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
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
refs["require"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "string" then
		return false, "[require] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

    local arg2RealInput = args[2]
	if args[2] and type(args[2]) == "boolean" and not args[3] then
        arg2RealInput = nil
		args[3] = args[2]
	elseif args[2] and type(args[2]) ~= "table" then
		return false, "[require] expected a list but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	if args[3] and type(args[3]) ~= "boolean" then
		return false, "[require] expected a boolean but received [3]: '" .. _local.typeof(args[3]) .. "'"
	end

    if (string.lower(string.sub(tostring(args[1]), -3, -1)) ~= ".ct") then
		return false, "[require] file not a cobalt script '" .. args[1] .. "' expected '.ct'"
    end

    local dir, file = args[1]:match("(.*/)([^/]+)$")
    local scriptPath = fs.check((dir or io.popen"cd":read'*l'), (file or args[1]))

	if not scriptPath then
		return false, "[require] path is not a valid file: '" .. tostring(args[1]) .. "'"
	end

    local read = fs.read(scriptPath)
	local s, r = require("src.index"):run(read or '(print (color "file read failed. Yes this is an error. Report this.", "red"))', arg2RealInput, false, true)

	if s and type(s) == "table" and s[1] == false then
		return false, s[2]
    end
	return true, s[2]
end
refs["clock"] = function(args, utils)
    return true, os.clock()
end
refs["delay"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[delay] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local number = tonumber(args[1])
    if number ~= nil then
        _local.wait(number)
    end
    return true
end
refs["max"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local all_numbers = {}
	local lastBigger = 0

	for i, v in args do
		if type(v) == "table" then
			for _i, _v in pairs(v) do
				if type(_v) ~= "number" then
					return false, "[max] expected a number but received [" .. tostring(i) .. "][" .. tostring(_i) .. "]: '" .. _local.typeof(_v) .. "'"
				end
				table.insert(all_numbers, _v)
			end
		elseif type(v) == "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local all_numbers = {}
	local lastSmaller = 0

	for i, v in args do
		if type(v) == "table" then
			for _i, _v in pairs(v) do
				if type(_v) ~= "number" then
					return false, "[min] expected a number but received [" .. tostring(i) .. "][" .. tostring(_i) .. "]:'" .. _local.typeof(_v) .. "'"
				end
				table.insert(all_numbers, _v)
			end
		elseif type(v) == "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "number" then
		return false, "[neg] expected a number but received [1]:'" .. _local.typeof(args[1]) .. "'"
	end

	return true, -args[1]
end
refs["+"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[+] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local r = 0
    local ok, msg = pcall(function()
        for i, v in pairs(args) do
            if _local.typeof(v) ~= "number" then
                return false, "expected a number but received [" .. tostring(i) .. "]:'" .. _local.typeof(v) .. "'"
            end
            r = r + tonumber(v)
        end
        return true
    end)
    if not ok then return {false, msg or "something unexpected happened during the sum."} end
    return true, r
end

refs["-"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    local r = table.remove(args, 1)
    if _local.typeof(r) ~= "number" then
        return false, "[-] expected a number but received [1]: '" .. _local.typeof(r) .. "'"
    end
    local ok, msg = pcall(function()
        for i, v in pairs(args) do
            if _local.typeof(v) ~= "number" then
                return false, "[-] expected a number but received [" .. tostring(i) .. "]:'" .. _local.typeof(v) .. "'"
            end
            r = r - tonumber(v)
        end
        return true
    end)
    if not ok then return {false, msg or "something unexpected happened during the sub"} end
    return true, r
end

refs["*"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    local r = table.remove(args, 1)
    if _local.typeof(r) ~= "number" then
        return false, "[*] expected a number but received [1]: '" .. _local.typeof(r) .. "'"
    end
    local ok, msg = pcall(function()
        for i, v in pairs(args) do
            if _local.typeof(v) ~= "number" then
                return false, "[*] expected a number but received [" .. tostring(i) .. "]:'" .. _local.typeof(v) .. "'"
            end
            r = r * tonumber(v)
        end
        return true
    end)
    if not ok then return {false, msg or "something unexpected happened during the mul"} end
    return true, r
end

refs["^"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[^] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[^] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return args[1] ^ args[2]
    end)
    if not ok then return {false, msg or "something unexpected happened during the expo"} end
    return true, result
end

refs["**"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[**] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return args[1] ^ 2
    end)
    if not ok then return {false, msg or "something unexpected happened during the square expo"} end
    return true, result
end

refs["***"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[***] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return args[1] ^ 3
    end)
    if not ok then return {false, msg or "something unexpected happened during the cubic expo"} end
    return true, result
end

refs["/"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[/] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[/] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return args[1] / args[2]
    end)
    if not ok then return {false, msg or "something unexpected happened during the div"} end
    return true, result
end

refs["%"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[%] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[%] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return args[1] % args[2]
    end)
    if not ok then return {false, msg or "something unexpected happened during the mod div"} end
    return true, result
end

refs["lorem"] = function(args, utils)
    return true, "Lorem ipsum dolor sit, amet consectetur adipisicing elit. Laborum, quas! Illum blanditiis, sed, earum vitae in laboriosam sint neque vero quos animi sunt nesciunt repudiandae qui? Voluptate possimus natus optio."
end

refs["date"] = function(args, utils)
    return true, string.split(os.date("%d/%m/%Y", os.time()), "/")
end

refs["time"] = function(args, utils)
    return true, string.split(os.date("%H:%M:%S", os.time()), ":")
end
refs["random"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
		return false, "[random] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "number" then
		return false, "[random] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.random(args[1], args[2])
	end)
	if not success then return {false, msg or "something unexpected happened during the random"} end
	return true, result
end
refs["lerp"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[lerp] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if _local.typeof(args[2]) ~= "number" then
        return false, "[lerp] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
    end
    if _local.typeof(args[3]) ~= "number" then
        return false, "[lerp] expected a number but received [3]: '" .. _local.typeof(args[3]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return _local.lerp(args[1], args[2], args[3])
    end)
    if not ok then return {false, msg or "something unexpected happened during the lerp"} end
    return true, result
end
refs["floor"] = function(args, utils)
    args = _local.resolveArgs(args, utils)
    if _local.typeof(args) == "list" and args[1] == "_!!dDecodePSCFail!!_" then 
        return false, args[2] 
    end
    if _local.typeof(args[1]) ~= "number" then
        return false, "[floor] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    local ok, result, msg = pcall(function()
        return math.floor(args[1])
    end)
    if not ok then return {false, msg or "something unexpected happened during the floor"} end
    return true, result
end

refs["abs"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
		return false, "[cos] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	local success, result, msg = pcall(function()
		return math.cos(args[1])
	end)
	if not success then return {false, msg or "something unexpected happened during the cos"} end
	return true, result
end
refs["acos"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
		return false, "[atan] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
		return false, "[log] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
		return false, "[noise] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[1]) ~= "number" then
		return false, "[noise] expected a number but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	if type(args[1]) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	local numbers = {}

	for i, v in args do
		if type(v) ~= "number" then
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
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	local success, result, msg = pcall(function()
		return json.encode(args[1])
	end)
	if not success then return false, msg or "encode error." end
	return true, result
end
refs["json-decode"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end
	
	local success, result, msg = pcall(function()
		return jsonObjToTable(args[1])
	end)
	if not success then return false, msg or "decode error." end
	return true, result
end
refs["http-get"] = function(args, utils)
    args = _local.resolveArgs(args, utils)

    -- Verificação dos parâmetros
    if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then
        return false, args[2]
    end
    if type(args[1]) ~= "string" then
        return false, "[http-post] [url] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if args[2] and type(args[3]) ~= "table" then
        return false, "[http-post] [headers] expected a table but received [3]: '" .. _local.typeof(args[3]) .. "'"
    end
    if string.sub(args[1], 1, 7) ~= "http://" and string.sub(args[1], 1, 8) ~= "https://" then
        return false, "[http-post] expected a valid URL, expected http:// or https://, received [1]: '" .. args[1] .. "'"
    end

    -- Criar um log único para a resposta
    local logID = tostring(#fs.list(temporary.paths.http))
    local file = temporary.paths.http .. "/" .. logID

    -- Monta os cabeçalhos (headers)
    local header_cmd = ""
    if args[2] then
        for key, value in pairs(args[3]) do
            header_cmd = header_cmd .. string.format('-H "%s: %s" ', key, value)
        end
    end
    
    local cmd = string.format('curl -s -w "%%{http_code}" -o %s %s %s', file, header_cmd, args[1])
    local success, result = pcall(function()
        local handle = io.popen(cmd)
        if handle then
            local response = handle:read("*a")
            handle:close()
            return response
        else
            return error("[http-post] Failed to execute curl command")
        end
    end)

    local status_code = tonumber(result:sub(-3)) or 500
    local response_body = "none xd"
    local res_file = io.open(file, "r")
    if res_file then
        response_body = res_file:read("*a")
        res_file:close()
    end

    if not success then
        return false, "[http-post] HTTP request failed: " .. (result or "unknown error")
    end

    if status_code == 0 then
        return false, {status_code, "verify device internet connection. If using http, verify if exists."}
    elseif status_code >= 400 then
        return false, {status_code, "http issue"}
    end

    return true, {status_code, response_body}
end
refs["http-post"] = function(args, utils)
    args = _local.resolveArgs(args, utils)

    -- Verificação dos parâmetros
    if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then
        return false, args[2]
    end
    if type(args[1]) ~= "string" then
        return false, "[http-post] [url] expected a string but received [1]: '" .. _local.typeof(args[1]) .. "'"
    end
    if args[3] and type(args[3]) ~= "table" then
        return false, "[http-post] [headers] expected a table but received [3]: '" .. _local.typeof(args[3]) .. "'"
    end
    if string.sub(args[1], 1, 7) ~= "http://" and string.sub(args[1], 1, 8) ~= "https://" then
        return false, "[http-post] expected a valid URL, expected http:// or https://, received [1]: '" .. args[1] .. "'"
    end

    -- Criar um log único para a resposta
    local logID = tostring(#fs.list(temporary.paths.http))
    local file = temporary.paths.http .. "/" .. logID

    -- Monta os cabeçalhos (headers)
    local header_cmd = ""
    if args[3] then
        for key, value in pairs(args[3]) do
            header_cmd = header_cmd .. string.format('-H "%s: %s" ', key, value)
        end
    end

    -- Se houver body e não houver Content-Type, adiciona Content-Type: application/json
    if args[2] and (not args[3] or not args[3]["Content-Type"]) then
        header_cmd = header_cmd .. '-H "Content-Type: application/json" '
    end

    -- Verifica se há corpo (body) e o codifica (somente se for uma tabela)
    local body_cmd = ""
    if args[2] then
        if type(args[2]) == "table" then    
            body_cmd = string.format("-d \"%s\"", string.gsub(json.encode(args[2]), "\"", "\\\""))
        else
            body_cmd = string.format("-d \"%s\"", string.gsub(json.encode({args[2]}), "\"", "\\\""))
        end
    end

    local cmd = string.format('curl -s -w "%%{http_code}" -o %s %s %s %s', file, header_cmd, body_cmd, args[1])
    local success, result = pcall(function()
        local handle = io.popen(cmd)
        if handle then
            local response = handle:read("*a")
            handle:close()
            return response
        else
            return error("[http-post] Failed to execute curl command")
        end
    end)

    local status_code = tonumber(result:sub(-3)) or 500
    local response_body = "none xd"
    local res_file = io.open(file, "r")
    if res_file then
        response_body = res_file:read("*a")
        res_file:close()
    end

    if not success then
        return false, "[http-post] HTTP request failed: " .. (result or "unknown error")
    end

    if status_code == 0 then
        return false, {status_code, "verify device internet connection. If using http, verify if exists."}
    elseif status_code >= 400 then
        return false, {status_code, "http issue"}
    end

    return true, {status_code, response_body}
end




-- (print (http-post "http://a" (object test [1,2,3,4]) (object test abc)))
refs["object"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if #args % 2 ~= 0 then
		return false, "[object] expected a pair for each arguments, received " .. tostring(#args) .. ", expected " .. tostring(#args+1) .. " or " .. tostring(#args-1) .. "."
	end

	local result = {}
	local run = 0
	for i = 1, #args, 2 do
		run = run + 1
		local indexName = args[i]
		local valueData = args[i+1]

		if type(indexName) ~= "string" then
			return false, "[object] expected a string for index names but received [" .. tostring(run) .. "]: '" .. _local.typeof(indexName) .. "'"
		end

		result[indexName] = valueData
	end

	return true, result
end
refs["version"] = function(args, utils)
    local language = require("language")
    return true, language.version
end
refs["odd?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "number" then
		return false, "[odd] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, args[1] % 2 == 0
end
refs["even?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "number" then
		return false, "[even] expected a number but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end

	return true, args[1] % 2 ~= 0
end
refs["bool?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, type(args[1]) == "boolean"
end
refs["num?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, type(args[1]) == "number"
end
refs["str?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, type(args[1]) == "string"
end
refs["list?"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	return true, type(args[1]) == "table"
end
refs["filter"] = function(args, utils)
	args = _local.resolveArgs(args, utils)
	if type(args) == "table" and args[1] == "_!!dDecodePSCFail!!_" then return false, args[2] end

	if type(args[1]) ~= "table" then
		return false, "[filter] expected a list but received [1]: '" .. _local.typeof(args[1]) .. "'"
	end
	if type(args[2]) ~= "string" then
		return false, "[filter] expected a function name as a string but received [2]: '" .. _local.typeof(args[2]) .. "'"
	end

	local togo;
	if type(args[1]) == "table" then
		togo = {}
        
		for i, v in pairs(args[1]) do
			if type(v) == "table" then
				v = _local.tableToString(v)
			end
			local returns = require("src.index"):run("(" .. args[2] .. " " .. v .. ")", nil, true)

			if returns[1] == false then
				return false, "[filter] [2] function: "  .. (returns[2] or "")
			end
			if type(returns[2]) ~= "boolean" then
				local addition = _local.typeof(returns[2])

				if type(returns[2]) == "string" then
					addition = returns[2]
				end

				return false, "[filter] [1][" .. tostring(i) .. "] function did not return a boolean, function returned: (" .. args[2] .. " " .. v .. "): '" .. addition .. "'"
			end

			if returns[2] == true then
				table.insert(togo, v)
			end
		end
	end

	return true, togo
end

return refs
