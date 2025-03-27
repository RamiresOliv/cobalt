local _module = {}

---------------------------
-- Simulação de Instâncias
---------------------------
local ReplicatedStorage = {
  root = { 
    Name = "root", 
    Parent = nil, 
    Children = {}  -- Aqui você adiciona os "filhos" manualmente
  }
}

---------------------------
-- Funções de Arquivo
---------------------------
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

if not string.split then
  function string.split(input, sep)
    sep = sep or "/"
    local t = {}
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
      table.insert(t, str)
    end
    return t
  end
end

local function FindFirstChild(instance, childName)
  if instance.Children then
    for _, child in ipairs(instance.Children) do
      if child.Name == childName then
        return child
      end
    end
  end
  return nil
end

local function getInstanceFromPath(pathStr)
  local parts = string.split(pathStr, "/")
  local instance = ReplicatedStorage.root
  for i, part in ipairs(parts) do
    if part ~= "root" then
      instance = FindFirstChild(instance, part)
      if not instance then break end
    end
  end
  return instance
end

_module.getFullPath = function(instance, utils)
  local path = ""
  local current = instance
  while current do
    if path == "" then
      path = current.Name
    else
      path = current.Name .. "/" .. path
    end
    if current == ReplicatedStorage.root then break end
    current = current.Parent
  end
  return path
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

---------------------------
-- Função getPath com cd armazenado em arquivo
---------------------------
-- Caminho do arquivo que armazena o cd (diretório atual)
local cdFilePath = "global/values/cd.txt"

-- Para que getPath funcione, o parâmetro "utils" precisa conter "root"
local utils = { root = ReplicatedStorage.root }
_module.utils = utils  -- opcional, para acesso fácil

_module.getPath = function(dir, utils)
  -- Lê o cd atual do arquivo
  local currentPathStr = readFile(cdFilePath)
  if not currentPathStr or currentPathStr == "" then
    currentPathStr = "root"
    writeFile(cdFilePath, currentPathStr)
  end

  -- Converte o cd atual para uma instância
  local progress = getInstanceFromPath(currentPathStr)
  if not progress then
    progress = ReplicatedStorage.root
  end

  -- Função interna para resolver cada parte do caminho
  local function work(toSolve)
    if toSolve == "root" then
      progress = utils.root
      return true
    elseif toSolve == ".." then
      if progress ~= utils.root then
        progress = progress.Parent
        return true
      else
        return false, "invalid parent. It's the limit."
      end
    elseif toSolve == "." then
      return true
    else
      local child = FindFirstChild(progress, toSolve)
      if child then
        progress = child
        return true
      else
        return false, "thing not found or is not the same type"
      end
    end
  end

  -- Se o caminho começar com "root", iniciamos no root
  if string.sub(dir, 1, 4) == "root" then
    progress = ReplicatedStorage.root
  end

  -- Se o caminho contém separadores ("/"), quebramos em partes
  if string.find(dir, "/") then
    local parts = string.split(dir, "/")
    for i, part in ipairs(parts) do
      local r, desc = work(part)
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

  -- Atualiza o arquivo cd.txt com o novo caminho
  local newPathStr = _module.getFullPath(progress, utils)
  writeFile(cdFilePath, newPathStr)

  return true, progress
end

return _module
