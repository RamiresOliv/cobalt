local fs = {}

local folder = ""
local success, _ = pcall(function()
  local path = debug.getinfo(1, "S").source:sub(2)--:gsub("\\", "/")
  folder = path:match("(.*\\)") or ".\\"

  package.cpath = package.cpath .. ";" .. folder .. "..\\modules\\?.dll;"
end)

if not success then
  package.cpath = package.cpath .. ";..\\modules\\?.dll;"
end

local lfs = require("luafs")

function fs.attributes(path, attr)
  local attributes, err = lfs.attributes(path)
  if not attributes then
    return nil, "cannot access " .. path
  end

  if attributes.mode == "file" or attributes.mode == "directory" then
    -- already
  else
    attributes.mode = "other"
  end

  if attr then
    local value = attributes[attr]
    if value == nil then
      return nil, "attribute not found"
    end
    return value
  end
  return attributes
end

function fs.chdir(path)
  local ok, err = lfs.chdir(path)
  if not ok then
    return nil, "cannot change directory to " .. path
  end
  return true
end

function fs.currentdir()
  local dir, err = lfs.currentdir()
  if not dir then
    return false, "cannot get current directory"
  end
  return dir
end

function fs.dir(path)
  local attr, err = lfs.attributes(path)
  if not attr or attr.mode ~= "directory" then
    return function() return nil end
  end

  local iter, dir_obj = lfs.dir(path)
  return function()
    while true do
      local entry = iter(dir_obj)
      if not entry then return nil end
      if entry ~= "." and entry ~= ".." then
        return entry
      end
    end
  end
end

function fs.touch(path)
  local file, err = io.open(path, "ab")
  if not file then
    return false, "cannot update/create " .. path
  end
  file:close()
  return true
end

function fs.isdir(path)
  local attr = lfs.attributes(path)
  return attr and attr.mode == "directory" or false
end

function fs.isfile(path)
  local attr = lfs.attributes(path)
  return attr and attr.mode == "file" or false
end

function fs.list(path)
  local list = {}
  for entry in fs.dir(path) do
    table.insert(list, entry)
  end
  return list
end

function fs.mkdir(path)
  local ok, err = lfs.mkdir(path)
  if not ok then
    return false, "Erro ao criar o diretório: " .. err
  end
  return true
end

function fs.filesize(path)
  local attr, err = lfs.attributes(path)
  if not attr then
    return nil, "cannot access " .. path
  end
  return attr.size
end

function fs.remove(path)
  local attr = lfs.attributes(path)
  if not attr then
    return false, "cannot access " .. path
  end

  if attr.mode == "directory" then
    local ok, err = lfs.rmdir(path)
    if not ok then
      return false, "cannot remove directory " .. path
    end
  else
    local ok, err = os.remove(path)
    if not ok then
      return false, "cannot remove file " .. path
    end
  end
  return true
end

function fs.rename(oldpath, newpath)
  local ok, err = os.rename(oldpath, newpath)
  if not ok then
    return false, "cannot rename " .. oldpath .. " to " .. newpath
  end
  return true
end

function fs.read(filePath)
  local read = lfs.read(filePath)
  if not read then
    return nil, "cannot open file " .. filePath .. " for reading"
  end
  return read
end

function fs.read2(filePath)
  local f, err = io.open(filePath, "r")
  if not f then
    return nil, "cannot open file " .. filePath .. " for reading"
  end
  local content = f:read("*a")
  f:close()
  return content
end

function fs.write(filePath, content)
  local f, err = io.open(filePath, "w")
  if not f then
    return nil, "cannot open file " .. filePath .. " for writing"
  end
  local ok, err = f:write(content)
  f:close()
  if not ok then
    return nil, "error writing to " .. filePath
  end
  return true
end

function fs.check(path)
  local dir, childName = path:match("^(.-)[/\\]?([^/\\]+)$")
  if dir == "" then
    dir = "."
  end

  local folder = fs.list(dir)
  if not folder then return false end

  for _, file in ipairs(folder) do
    if file == childName then
      return true
    end
  end
  return false
end

function fs.check2(dir, childName)
  for _, file in ipairs(fs.list(dir)) do
    if file == childName then
      return dir .. "/" .. file
    end
  end
  return nil
end

function fs.check3(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

return fs