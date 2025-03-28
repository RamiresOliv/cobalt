local json = require("modules.dkjson")
local arguments = require("src.args")
local utils = require("src.utils")
local api = require("src.api")
local runtime = require("src.runtime")
local cli = require("src.cli")
local fs = require("src.filesystem")

ShouldClearTempsAfterDone = true;

local me = {}

local script_dir_raw = debug.getinfo(1, "S").source:sub(2):match("(.+)[/\\]")
local script_dir = ""
if script_dir_raw ~= ".\\src" then script_dir = script_dir_raw .. "\\..\\" end

local temporary = {
  paths = {
    http = "./temp/client",
    functions = "./temp/funcs",
    variables = "./temp/vars"
  }
}

temporary.check = function()
  if not fs.check(script_dir .. "/temp") then
    fs.mkdir(script_dir .. "/" .. "temp")
    fs.mkdir(script_dir .. "/" .. "temp/funcs")
    fs.mkdir(script_dir .. "/" .. "temp/client")
    fs.mkdir(script_dir .. "/" .. "temp/vars")
  end
  if not fs.check(script_dir .. "/temp/funcs") then
    fs.mkdir(script_dir .. "/" .. "temp/funcs")
  end
  if not fs.check(script_dir .. "/temp/client") then
    fs.mkdir(script_dir .. "/" .. "temp/client")
  end
  if not fs.check(script_dir .. "/temp/vars") then
    fs.mkdir(script_dir .. "/" .. "temp/vars")
  end
end
temporary.check()

temporary.clear = function()
  temporary.check()
  for _, file in ipairs(fs.list(script_dir .. "/" .. temporary.paths.http)) do
    fs.remove(script_dir .. "/" .. temporary.paths.http .. "/" .. file)
  end
  for _, file in ipairs(fs.list(script_dir .. "/" .. temporary.paths.functions)) do
    fs.remove(script_dir .. "/" .. temporary.paths.functions .. "/" .. file)
  end
  for _, file in ipairs(fs.list(script_dir .. "/" .. temporary.paths.variables)) do
    fs.remove(script_dir .. "/" .. temporary.paths.variables .. "/" .. file)
  end
end

function testConvert(v)
  v = tostring(v)
  for _, file in ipairs(fs.list(script_dir .. temporary.paths.variables)) do
    local filePath = script_dir .. temporary.paths.variables .. "/" .. file
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

-- eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
function me:init(code, rawArgs, mustReturn)
  temporary.check()
  temporary.clear()
  local run = me:run(code, rawArgs, mustReturn)
  if ShouldClearTempsAfterDone then temporary.clear() end
  return run;
end

-- help me
function me:run(code, rawArgs, mr)
  temporary.check()

  local proccess = 0
  if mr == nil then mr = false end
  if not code then return {false, "empty request."} end

  local success, returns = pcall(function()
		local lines = code:gsub("\n?;[^\n]*", ""):gsub("	", ""):split("\n")
		local lines_concats = table.concat(lines, " ")
		for match in lines_concats:gmatch("%b()") do
      proccess = proccess + 1

      local base_args = getLine(match)
      local base_funcName = table.remove(base_args, 1)

      if not base_funcName then return {false, 'incomplete statement.'} end

      local scriptFuncExists = fs.check(script_dir .. temporary.paths.functions .. "/" .. base_funcName .. ".json")
      local functionData = api.mapping[base_funcName]

      if not scriptFuncExists and not functionData then
        return {false, "unknown syntax/function: '" .. (base_funcName or "nil") .. "'"}
      end

      for i, v in ipairs(base_args) do
        base_args[i] = arguments:indexArgHandler(v, rawArgs)
      end

      local function describe(value, expected)
        value = testConvert(value)
        local toNumberPcallSuccess, r = pcall(function() return tonumber(tostring(value)) end)
        if toNumberPcallSuccess and r ~= nil then
          value = tonumber(tostring(value))
        end

        local canStringfy = false
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
            local vType, stringfy = describe(v_args, functionData.params[#functionData.params])
            if v == "any" or vType == "any" or vType == "function" or v == vType then
              foundExpect = true
              break
            end
          end

          if not foundExpect then
            return {false, "[" .. base_funcName .. "] expected " .. tostring(argExpects) .. " but received [" .. tostring(i_args) .. "]: '" .. utils.typeof(v_args) .. "'"}
          end
          ::continue::
        end

        local funcRefFunc = runtime[base_funcName]
        if not funcRefFunc then return {false, "Function reference doesn't exist. (prob of a huge bug)"} end

        local state, data, refuseStop = funcRefFunc(base_args)

        if type(data) == "table" and data[1] == "_-!@!_-!-return-and-stop-rn!" then return {true, data[2], nil, true} end
        if data ~= nil and type(data) == "table" and (data[1] == "_-!@!_-!-continue-skip-this-thing-rn!" or data[1] == "_-!@!_-!-break-and-stop-rn!") then return {true, nil, nil, true} end
        if state == false then return {false, data} end
        if mr == true then return {true, data, refuseStop} end
      elseif scriptFuncExists then
        local content = fs.read(script_dir .. temporary.paths.functions .. "/" .. base_funcName .. ".json")
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

          local r, returns = me:run(c, nil, true)
          if r[1] == false then
            print(cli.colorize("[" .. base_funcName .. "] Error origin in function '" .. base_funcName .. "': " .. tostring(r[2] or "unknown"), "red"))
            return {false, r[2]}
          end

          if mr == true then
            return {true, arguments:indexArgHandler(r[2], rawArgs), r[4]}
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
    temporary.clear()
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

function me:fixArgs(player, code, rawArgs)
  for match in code:gmatch("%b()") do
    local args = getLine(match)
    for i, v in ipairs(args) do
      args[i] = arguments:indexArgHandler(v, rawArgs)
    end
  end
  return code
end

return me
