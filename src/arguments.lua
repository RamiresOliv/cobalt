local args_handler = {}

local utils = require("src.utils")         -- Ajuste o caminho conforme necessário
local constants = require("src.constants")() -- Presume que o módulo retorna uma função que precisa ser chamada

function args_handler.indexArgHandler(self, v, args)
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
    v = "_!str!_-" .. tostring(utils.stringToHex(v:sub(2, -2)))
  elseif v == "true" then
    v = true
  elseif v == "false" then
    v = false
  elseif v == "nil" then
    v = nil
  else
    if type(v) == "string" then
      for key, value in pairs(constants) do
        v = v:gsub("{" .. tostring(key) .. "}", tostring(value))
      end
    end
  end

  return v
end

return args_handler
