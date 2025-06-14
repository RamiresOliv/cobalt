local json = require("modules.dkjson")
local tools = require("src.tools")
local api = require("src.api")
local runtime = require("src.runtime")
local metadata = require("src.metadata")
local cli = require("src.cli")
local fs = require("src.filesystem")
local me = {}

-- public params: (debug stuff etc)
ShouldClearTempsAfterDone = true;
AllowDebugPrints = false; -- nuh uh

-------------------------------------------- code
function IndexArgHandler(v, args)
  v = tostring(v)

  if type(args) == "table" then
    for key, value in pairs(args) do
      v = v:gsub("{%%" .. tostring(key) .. "}", tostring(value))
    end
  end

  local success, n = pcall(function()
    return tonumber(v)
  end)
  if success and n ~= nil then
    v = n
  elseif v:sub(1, 1) == '"' and v:sub(-1) == '"' then
    v = "_!str!_-" .. tostring(tools.stringToHex(v:sub(2, -2)))
  elseif v == "true" then
    v = true
  elseif v == "false" then
    v = false
  elseif v == "nil" then
    v = nil
  else
    if type(v) == "string" then
      for key, value in pairs(metadata:constants()) do
        v = v:gsub("{" .. tostring(key) .. "}", tostring(value))
      end
    end
  end

  return v
end

function TestConvert(v)
  v = tostring(v)
  for _, file in ipairs(fs.list(tools.globals.dir .. tools.globals.temporary.paths.variables)) do
    local filePath = tools.globals.dir .. tools.globals.temporary.paths.variables .. "/" .. file
    local togoV = fs.read(filePath)

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

    if type(togoV) == "boolean" then
      togo = tostring(togoV)
    elseif type(togoV) == "string" and string.sub(togoV, 1, 1) == "[" and string.sub(togoV, -1) == "]" then
      togo = togoV
    end

    local final = togo
    if string.sub(tostring(togoV), 1, 1) == "{" and string.sub(tostring(togoV), -1) == "}" then
      final = '"' .. string.gsub(togoV, '"', "_$#@¨COMMA_CHAR¨@#$_") .. '"'
    end

    final = final:gsub("%%", "#")
    v = v:gsub("{" .. file .. "}", final)
  end
  return v
end

function SplitParentheses(str)
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

function GetLine(things)
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

-- eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
function me:init(code, rawArgs, mustReturn)
  tools.globals.temporary.check()
  tools.globals.temporary.clear()
  local run = me:run(code, rawArgs, mustReturn)
  if ShouldClearTempsAfterDone then tools.globals.temporary.clear() end
  return run;
end

-- help me
function me:run(code, rawArgs, mr, _COMPILER_RETURN_STATUS) -- NOTE: do not use _COMPILER_RETURN_STATUS. It's compiler usage only.
  tools.globals.temporary.check()

  local proccess = 0
  if mr == nil then mr = false end
  if not code then return {false, "empty request."} end

  local success, returns = pcall(function()
    local lines = {}
    for line in code:gsub("\n?;[^\n]*", ""):gsub("	", ""):gmatch("[^\n]+") do
      table.insert(lines, line)
    end
		local lines_concats = table.concat(lines, " ")
		for match in lines_concats:gmatch("%b()") do
      proccess = proccess + 1

      local base_args = GetLine(match)
      local base_funcName = table.remove(base_args, 1)

      if not base_funcName then return {false, 'incomplete statement.'} end

      local scriptFuncExists = fs.check(tools.globals.dir .. tools.globals.temporary.paths.functions .. "/" .. base_funcName .. ".json")
      local functionData = api.mapping[base_funcName]

      if not scriptFuncExists and not functionData then
        return {false, "unknown syntax/function: '" .. (base_funcName or "nil") .. "'"}
      end

      for i, v in ipairs(base_args) do
        base_args[i] = IndexArgHandler(v, rawArgs)
      end

      local function describe(value, expected)
        value = TestConvert(value)
        local toNumberPcallSuccess, r = pcall(function() return tonumber(tostring(value)) end)
        if toNumberPcallSuccess and r ~= nil then
          value = tonumber(tostring(value))
        end

        local canStringfy = false

        if value == "true" then
          value = true
        elseif value == "false" then
          value = false
        end

        local vType = type(value)
        if vType == "number" and expected == "string" then
          canStringfy = true
        elseif vType == "boolean" and expected == "string" then
          canStringfy = true
        end

        if vType == "string" then
          if value:sub(1, 1) == '(' and value:sub(-1) == ')' then
            local functionName = {}
            for word in value:sub(2, -2):gmatch("%S+") do
              table.insert(functionName, word)
            end
            functionName = functionName[1]
            local apiOfFunc = api.mapping[functionName]
            if not apiOfFunc then return "function" end

            local returnsList = {}
            for s in apiOfFunc.returns:gmatch("([^/]+)") do
              table.insert(returnsList, s)
            end
            for _, v in ipairs(returnsList) do
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
        if #base_args < functionData.requiredEntries then
          return {false, "[" .. base_funcName .. "] expected " .. tostring(functionData.requiredEntries) .. " entries, but received " .. tostring(#base_args)}
        end

        for i_args, v_args in ipairs(base_args) do
          local funcType = api.mapping[base_funcName]
          local argExpects = funcType.params[i_args]

          if funcType.openEntries == true and i_args > #funcType.params then
            argExpects = funcType.params[#funcType.params]
          elseif not argExpects then
            goto continue
          end

          local foundExpect = false
          for _, v in ipairs((function()
            local t = {}
            for s in argExpects:gmatch("([^/]+)") do
              table.insert(t, s)
            end
            return t
          end)()) do
            local vType, stringfy = describe(v_args, functionData.params[_])
            if v == "any" or vType == "any" or vType == "function" or v == vType then
              foundExpect = true
              break
            end
          end

          if not foundExpect then
            return {false, "[" .. base_funcName .. "] expected " .. tostring(argExpects) .. " but received [" .. tostring(i_args) .. "]: '" .. tools.typeof(v_args) .. "'"}
          end
          ::continue::
        end

        local funcRefFunc = runtime[base_funcName]
        if not funcRefFunc then return {false, "Function reference doesn't exist. (maybe huge bug)"} end

        local state, data, refuseStop = funcRefFunc(base_args)

        --if type(data) == "table" then print(data[1]) end -- debug
        if _COMPILER_RETURN_STATUS == true then return {true, data, refuseStop} end 
        if data ~= nil and type(data) == "table" and data[1] == "_-!@!_-!-return-and-stop-rn!" then return {true, data[2], nil, true} end
        if data ~= nil and type(data) == "table" and (data[1] == "_-!@!_-!-continue-skip-this-thing-rn!" or data[1] == "_-!@!_-!-break-and-stop-rn!") then return {true, nil, nil, true} end
        if state == false then return {false, data} end
        if mr == true then return {true, data, refuseStop} end
      elseif scriptFuncExists then
        local content = fs.read(tools.globals.dir .. tools.globals.temporary.paths.functions .. "/" .. base_funcName .. ".json")
        local s, decode = pcall(function()
          return json.decode(content)
        end)
        if not s then
          print(cli.colorize("[scriptFunction:invalid_JSON]: JSONDecode failed.", "red"))
          return {false, "Unable to run function, JSONDecode was unable to work with it."}
        end
        if type(decode) ~= "table" or not decode.arguments or not decode.commands then
          print(cli.colorize("[scriptFunction:invalid_format]: Invalid function data format; JSON was successful, but the data wasn't expected.", "red"))
          return {false, "Invalid function data format to run."}
        end

        local function run(c)
          for i, name in ipairs(decode.arguments) do
            c = c:gsub("{" .. name .. "}", tostring(base_args[i]))
          end

          local r = me:run(c, nil, true, true)
          if r[1] == false then
            print(cli.colorize("[" .. base_funcName .. "] Error origin in function '" .. base_funcName .. "': " .. tostring(r[2] or "unknown"), "red"))
            return {false, r[2]}
          end

          -- this should fix the return problems in functions. At least... is what I did and worked.
          if r ~= nil and type(r) == "table" and type(r[2]) == "table" and r[2][1] == "_-!@!_-!-return-and-stop-rn!" then return {true, r[2][2], true} end

          if mr == true then
            return {true, IndexArgHandler(r[2], rawArgs), r[4]}
          end

          return {true}
        end

        local get
        if type(decode) == "table" then
          for _, c in ipairs(decode.commands) do
            get = run(c)
            if get[3] == true then break end
            if type(get) == "table" and get[1] == false then break end
          end
        else
          get = run(tostring(decode.commands))
          if get[3] == true then break end
          if type(get) == "table" and get[1] == false then break end
        end

        if get ~= nil then
          return get
        end
      end
    end
  end)

  if not success then
    print(cli.colorize(cli.colorize("[Error]: High level error:", "magenta"), "bold"))
    print(returns)
    tools.globals.temporary.clear()
    os.exit()
    return {false, returns, true}
  elseif type(returns) == "table" and returns[1] == false then
    return {false, returns[2]}
  else
    if not returns then
      return {true}
    else
      return returns
    end
  end
end

-- apart.
function me:fixArgs(player, code, rawArgs)
  for match in code:gmatch("%b()") do
    local args = GetLine(match)
    for i, v in ipairs(args) do
      args[i] = IndexArgHandler(v, rawArgs)
    end
  end
  return code
end

tools.globals.temporary.check()
return me
