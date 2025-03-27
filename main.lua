local cobalt = require("call")
local language = require("src.language")
local types = require("src.types")

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
    print(returns[2])
    return;
end

function header()
    print("Cobalt " .. tostring(language.version) .. " (" .. _VERSION .. ") https://github.com/RamiresOliv/cobalt")
    print("declare 'help' for functions list and syntax assist.")
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
        header()

        local founds = input:split(" ")

        if #founds > 1 then
            local v = types.mapping[founds[2]]

            if not v then
                print("function named '" .. founds[2] .. "' has not been found.")
                
                local allIndexes = {}
                local rs = {}
                for i, _ in pairs(types.mapping) do
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

            r = ""
            for param_n, param in pairs(v.params) do
                if param_n <= v.requiredEntries then
                    r = r .. " " .. "{" .. param .. "}"
                else
                    r = r .. " " .. "[" .. param .. "]"
                end
            end
            if v.openEntries then
                r = r .. " ..."
            end
            if #r > 0 then
                r = " " .. r
            end
            print("(" .. founds[2] .. r .. ")" .. ": " .. v.returns)
            print("- " .. v.description)
            print(string.rep("-", #v.description + 3))
            
            goto continue
        end

        print("\27[1mcobalt usage:\27[0m")
        print([[
    (print "Hello World!"): "Hello World"
    (print (+ 10 10)): 20
    (print (format "Hello {1}!" (prompt "What is your name?"))): "Hello *input*!"
    (var input (prompt "let me guess the type!")) (print (format "it is: {1}" (type {input}))): "it is: *input read convertion*"
    (function mySum v1 v2 (return (+ {v1} {v2}))) (print (mySum 15 10)): 25
    (function checkThat v1 (return-if (== {v1} "no") (print (color "user said no!" "orange"))) (print "yes! {v1}")) (checkThat yes)
    (print (json-decode (listget (http-get http://api.open-notify.org/iss-now.json) 2)))
    (clear) (var phrase "Hello big world!") (for (len {phrase}) i (print (first {phrase} {i})))
        ]])
        print("\27[1mcobalt commands:\27[0m")
        for i, v in pairs(types.mapping) do
            r = ""
            for param_n, param in pairs(v.params) do
                if param_n <= v.requiredEntries then
                    r = r .. " " .. "{" .. param .. "}"
                else
                    r = r .. " " .. "[" .. param .. "]"
                end
            end
            if v.openEntries then
                r = r .. " ..."
            end
            if #r > 0 then
                r = " " .. r
            end
            print("    (" .. i .. r .. ")" .. ": " .. v.returns)
        end

        print("")
        print("{...} = required")
        print("[...] = optional")
        print("")
        print("looking for more info about an specific function? Use help <funcName>")
        goto continue
    end

    local run = cobalt(input)
    if run[1] == false then
        print("\27[31m" .. run[2] .. "\27[0m")
        print("\27[90mOops, missed something? Try help <funcName>\27[0m")
    end
end