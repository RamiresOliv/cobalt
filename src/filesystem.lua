local fs = {}

local path = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/")
local folder = path:match("(.*/)") or "./"

package.cpath = package.cpath .. ";" .. folder .. "../modules/?.dll;"
local lfs = require("luafs")

function fs.list(dir)
    local children = {}
    for file in lfs.dir(dir) do
      if file ~= "." and file ~= ".." then
        table.insert(children, file)
      end
    end
    return children
  end
  
function fs.read(filePath)
    local f = io.open(filePath, "r")
    if f then
      local content = f:read("*a")
      f:close()
      return content
    end
    return nil
  end
  
function fs.check(dir, childName)
    for _, file in ipairs(fs.list(dir)) do
      if file == childName then
        return dir .. "/" .. file
      end
    end
    return nil
end

function fs.exists(container, childName)
    for _, child in ipairs(container) do
        if child.Name == childName then
            return true
        end
    end
    return false
end

return fs