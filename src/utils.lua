local _module = {}

local function readFile(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

local function writeFile(path, content)
  return pcall(function()
    local file = io.open(path, "w")
    if file then
      file:write(content)
      file:close()
      return true
    end
    return error("file not found.")
  end)
end

_module.delay = function(n)
  local t0 = os.clock()
  while os.clock() - t0 <= n do end
end

_module.lerp = function(a, b, t)
  return a + (b - a) * t
end

_module.typeof = function(thing)
  local tpf = type(thing)
  if tpf == "table" then tpf = "list" end
  return tpf
end

_module.fixType = function(str)
  if str == "table" then str = "list" end
  return str
end

_module.concat = function(list, separator)
  for i, v in pairs(list) do
    list[i] = tostring(v)
  end
  return table.concat(list, (separator or " "))
end

_module.stringToHex = function(str)
  return (str:gsub('.', function(c)
    return string.format('%02X', string.byte(c))
  end))
end

_module.hexToString = function(str)
  return (str:gsub('..', function(c)
    return string.char(tonumber(c, 16))
  end))
end

return _module
