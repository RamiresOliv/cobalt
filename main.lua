pcall(function()
    local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.+)[/\\]")
    package.path = package.path .. ";" .. script_dir .. "/?.lua"
end)

local cobalt = require("call")
local metadata = require("src.metadata")
local api = require("src.api")

function tableToString(list)
    if type(list) ~= "table" then return nil end
    local dat = "["
    for i, v in ipairs(list) do
        if type(v) == "table" then
            v = tableToString(v)
        end
        dat = dat .. tostring(v)
        if i < #list then dat = dat .. ", " end
    end
    dat = dat .. "]"
    return dat
end

local filepath = arg[1]
if filepath then
    table.remove(arg, 1)

    args = ""
    if #arg > 0 then
        args = tableToString(arg)
    end

    local returns = cobalt('(require "' .. tostring(filepath) .. '" ' .. args .. ')', true)
    if returns[1] == false then
        print("\27[31m" .. returns[2] .. "\27[0m")
    end
    return;
end

function header()
    print("Cobalt " .. tostring(metadata.version) .. " (" .. _VERSION .. ") https://github.com/RamiresOliv/cobalt")
    print("use 'help' for functions list and syntax assist.")
    print("you can exit using 'exit' or CTRL+C")
end

header()
function string:split(delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )
    while delim_from do
      table.insert( result, string.sub( self, from , delim_from-1 ) )
      from  = delim_to + 1
      delim_from, delim_to = string.find( self, delimiter, from  )
    end
    table.insert( result, string.sub( self, from  ) )
    return result
end

while true do
    ::continue::
    io.write("> ")
    local input = io.read()
    
    if input == "exit" then
        print("main.lua break")
        break
    elseif input == "cls" then
        os.execute("cls")
        goto continue
    elseif input == "help" or input:split(" ")[1] == "help" then

        local founds = input:split(" ")

        if #founds > 1 then
            local v = api.mapping[founds[2]]
            if not v then
                print("\27[33mfunction named '" .. founds[2] .. "' has not been found.\27[0m")
                
                local allIndexes = {}
                local rs = {}
                for i in pairs(api.mapping) do
                    table.insert(allIndexes, i)
                end
                for _, v in pairs(allIndexes) do
                    if string.find(v, founds[2]) then
                        table.insert(rs, v)
                    end
                end
                if #rs > 0 then
                    print("maybe you mean by " .. table.concat(rs, ", ") .. "?")
                end
                
                goto continue
            end

            local r = ""
            for param_n, param in ipairs(v.params) do
                if param_n <= v.requiredEntries then
                    r = r .. " {" .. param .. "}"
                else
                    r = r .. " [" .. param .. "]"
                end
            end
            if v.openEntries then
                r = r .. " ..."
            end
            print("(\27[36m" .. founds[2] .. "\27[33m" .. r .. "\27[0m)" ..
                  "\27[0m\27[90m: " .. v.returns .. "\27[0m")
            print("\27[1m" .. v.description .. "\27[0m")
            print(string.rep("\27[90m-\27[0m", #v.description))
            goto continue
        end

        header()
        print("")
        print("\27[1mcobalt usage:\27[0m")
        print([[
    (print "Hello World!"): "Hello World"
    (print (+ 10 10)): 20
    (print (format "Hello {1}!" (input "What is your name?")))
    (var input (input "let me guess the type!")) (print (format "it is: {1}" (type {input})))
    (function mySum v1 v2 (return (+ {v1} {v2}))) (print (mySum 15 10))
    (function checkThat v1 (return-if (== {v1} "no") (print (color "user said no!" "orange"))) (print "yes! {v1}")) (checkThat yes)
    (print (json-decode (at (http-get http://api.open-notify.org/iss-now.json) 2)))
    (clear) (var phrase "Hello big world!") (for (len {phrase}) i (print (first {phrase} {i})))
        ]])
        print("\27[1mcobalt commands: (from api.lua)\27[0m")
        
        local keys = {}
        for k in pairs(api.mapping) do
            table.insert(keys, k)
        end
        table.sort(keys, function(a, b)
            return a < b
        end)
        for _, k in ipairs(keys) do
            local v = api.mapping[k]
            local r = ""
            for param_n, param in ipairs(v.params) do
                if param_n <= v.requiredEntries then
                    r = r .. " {" .. param .. "}"
                else
                    r = r .. " [" .. param .. "]"
                end
            end
            if v.openEntries then
                r = r .. " ..."
            end
            if #r > 0 then
                r = " " .. r
            end
            print("    (\27[36m" .. k .. "\27[31m" .. r .. "\27[0m)" .. "\27[0m\27[90m: " .. v.returns .. "\27[0m")
        end
        
        print("")
        print("{...} = required")
        print("[...] = optional")
        print("'...' = multiple arguments (MUST be the same type as the last value)")
        print("")
        print("\27[90mlooking for more info about an specific function? Use help <funcName>\27[0m")
        goto continue
    end

    local run = cobalt(input)
    if run[1] == false then
        print("\27[31m" .. run[2] .. "\27[0m")
        print("\27[90mOops, missed something? Try help <funcName>\27[0m")
    end
end