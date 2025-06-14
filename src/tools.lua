local json = require("modules.dkjson")
local fs = require("src.filesystem")
local me = { globals = {} }

local script_dir_raw = debug.getinfo(1, "S").source:sub(2):match("(.+)[/\\]")
local script_dir = ""
if script_dir_raw ~= "./src" then script_dir = script_dir_raw .. "/../" end

me.globals.dir = script_dir
me.globals.temporary = {
    size = {
        funcs = function()
            return #fs.list(me.globals.dir .. "temp/funcs")
        end,
        http = function()
            return #fs.list(me.globals.dir .. "temp/client")
        end,
        variables = function()
            return #fs.list(me.globals.dir .. "temp/vars")
        end,
    },
    paths = {
        http = "./temp/client",
        functions = "./temp/funcs",
        variables = "./temp/vars"
    },
    check = function()
        -- renames to me.globals.temporary.paths<name> laterrrrrrrrr
        if not fs.check(me.globals.dir .. "/temp") then
            fs.mkdir(me.globals.dir .. "temp")
            fs.mkdir(me.globals.dir .. "temp/funcs")
            fs.mkdir(me.globals.dir .. "temp/client")
            fs.mkdir(me.globals.dir .. "temp/vars")
        end
        if not fs.check(me.globals.dir .. "/temp/funcs") then
            fs.mkdir(me.globals.dir .. "temp/funcs")
        end
        if not fs.check(me.globals.dir .. "/temp/client") then
            fs.mkdir(me.globals.dir .. "temp/client")
        end
        if not fs.check(me.globals.dir .. "/temp/vars") then
            fs.mkdir(me.globals.dir .. "temp/vars")
        end
    end,

    clear = function()
        for _, file in pairs(fs.list(script_dir .. me.globals.temporary.paths.http)) do
            fs.remove(script_dir .. me.globals.temporary.paths.http .. "/" .. file)
        end
        for _, file in pairs(fs.list(script_dir .. me.globals.temporary.paths.functions)) do
            fs.remove(script_dir .. me.globals.temporary.paths.functions .. "/" .. file)
        end
        for _, file in pairs(fs.list(script_dir .. me.globals.temporary.paths.variables)) do
            fs.remove(script_dir .. me.globals.temporary.paths.variables .. "/" .. file)
        end
    end
}

me.wait = function(n)
    local t0 = os.clock()
    while os.clock() - t0 <= n do end
end

me.lerp = function(a, b, t)
    return a + (b - a) * t
end

me.concat = function(list, separator)
    for i, v in pairs(list) do
        list[i] = tostring(v)
    end
    return table.concat(list, separator or " ")
end

me.typeof = function(thing)
    local t = type(thing)
    if t == "table" then t = "list" end
    return t
end

me.stringToHex = function(str)
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

me.hexToString = function(str)
    return (str:gsub('..', function(c)
        return string.char(tonumber(c, 16))
    end))
end

me.tableToString = function(list)
    if me.typeof(list) ~= "list" then return nil end
    local dat = "["
    for i, v in ipairs(list) do
        if me.typeof(v) == "list" then
            v = me.tableToString(v)
        end
        dat = dat .. tostring(v)
        if i < #list then dat = dat .. ", " end
    end
    dat = dat .. "]"
    return dat
end

me.split = function(inputstr, sep)
    if sep == nil or sep == "" then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

me.jsonObjToTable = function(json_obj)
    local v = json.decode(json_obj)
    local function convertTable(t)
        local result = {}
        for _, value in pairs(t) do
            if me.typeof(value) == "list" then
                table.insert(result, convertTable(value))
            else
                table.insert(result, value)
            end
        end
        return result
    end
    if me.typeof(v) == "list" then
        return convertTable(v)
    else
        return v
    end
end

return me
