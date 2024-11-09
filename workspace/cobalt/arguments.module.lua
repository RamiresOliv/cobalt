local args_handler = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local temporary = ReplicatedStorage:WaitForChild("temporary")

local utils = require(script.Parent.utils)

function args_handler:indexArgHandler(v: string, arguments: {any}?)
	v = tostring(v)

	local toNumberPcallSuccess, n = pcall(function()
		return tonumber(v)
	end)
	if toNumberPcallSuccess and n ~= nil then
		v = n
	elseif v:sub(1, 1) == '"' and v:sub(-1, -1) == '"' then
		v = "_!str!_-" .. tostring(utils.stringToHex(v:sub(2, -2)))
	elseif v == "true" then
		v = true
	elseif v == "false" then
		v = false
	elseif v == "nil" then
		v = nil
	else
		--[[for _, v_var in pairs(temporary.values:GetChildren()) do
			if v_var:IsA("StringValue") then
				local togoV = v_var.Value

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

				if typeof(togoV) == "boolean" then
					togo = tostring(togoV)
				elseif typeof(togoV) == "string" and string.sub(togoV, 1, 1) == "[" and string.sub(togoV, -1, -1) == "]" then
					togo = togoV
				end


				local final = togo
				if string.sub(tostring(togoV), 1, 1) == "{" and string.sub(tostring(togoV), -1, -1) == "}" then
					final = '"' .. string.gsub(togoV, '"', "_$#@¨COMMA_CHAR¨@#$_") .. '"'
				end

				--local final = togo
				--if string.sub(tostring(togoV), 1, 1) == "{" and string.sub(tostring(togoV), -1, -1) == "}" then
				--	final = '"' .. togoV .. '"'
				--end

				final = final:gsub("%%", "#")
				v = v:gsub("{" .. v_var.Name .. "}", final)
			end
		end]]

		local constants = require(script.Parent.constants)()
		if typeof(v) == "string" then
			for i_, v_ in constants do
				local a = constants[i_]
				v = v:gsub("{" .. tostring(i_) .. "}", tostring(a))
			end
			if arguments then
				for i_, v_ in arguments do
					v = v:gsub("{%%" .. tostring(i_) .. "}", tostring(v_))
				end
			end
		end
	end

	return v
end

return args_handler