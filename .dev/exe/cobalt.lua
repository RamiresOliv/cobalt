local path = os.getenv("PATH")

function goodbye()
    print("[cobalt.exe]: saying goodbye!")
end

if path and string.find(path, "lua") then
    if #arg > 0 then
        os.execute("lua main.lua " .. table.concat(arg, " "))
    else
        os.execute("lua main.lua")
    end
else
    if #arg > 0 then
        os.execute('call "bin/lua54.exe" main.lua ' .. table.concat(arg, " "))
    else
        print("[cobalt.exe][lua54.exe] 'lua' not found in os.env.PATH")
        os.execute('call "bin/lua54.exe" main.lua')
    end
end

if #arg == 0 then
    goodbye()
end