local highlighter = {}
local types = require(game:GetService("ReplicatedStorage").cobalt.types).mapping

local keywords = {
	cobalt = {},
	operators = {
		"=", "~", ">", "<", ">=", "<="
	},
	specialOperators = {
		",", "(", ")", "{", "}", "[", "]", ":"
	}
}

--[[
huge thanks to NiceBuild1! <3 ;)

https://devforum.roblox.com/t/realtime-richtext-lua-syntax-highlighting/2500399
]]

function organize(t)
	local l = {}
	local n = {}
	local e = {}

	for _, v in ipairs(t) do
		if v:match("%a") then
			table.insert(l, v)
		elseif tonumber(v) then
			table.insert(n, v)
		else
			table.insert(e, v)
		end
	end

	local r = {}
	for _, v in ipairs(l) do table.insert(r, v) end
	for _, v in ipairs(n) do table.insert(r, v) end
	for _, v in ipairs(e) do table.insert(r, v) end

	return r
end

for i, v in types do
	table.insert(keywords.cobalt, i)
end
keywords.cobalt = organize(keywords.cobalt)
table.insert(keywords.cobalt, "else")

local colors = {
	numbers = 			Color3.fromRGB(255, 247, 189),
	boolean = 			Color3.fromRGB(255, 217, 155),
	null = 				Color3.fromRGB(255, 247, 189),
	operator = 			Color3.fromRGB(255, 247, 189),
	function_call = 	Color3.fromRGB(130, 170, 255),
	var_name = 			Color3.fromRGB(170, 130, 255),
	spec_operator = 	Color3.fromRGB(177, 177, 177),
	cobalt = 			Color3.fromRGB(255, 112, 122),
	str = 				Color3.fromRGB(138, 255, 138),
	comment = 			Color3.fromRGB(121, 131, 132),
}

local function createKeywordSet(keywords)
	local keywordSet = {}
	for _, keyword in ipairs(keywords) do
		keywordSet[keyword] = true
	end
	return keywordSet
end

local cobaltSet = createKeywordSet(keywords.cobalt)
local operatorsSet = createKeywordSet(keywords.operators)
local specialOperatorsSet = createKeywordSet(keywords.specialOperators)

local functionNames = {}
local function getHighlight(tokens, index)
	local token = tokens[index]

	if tonumber(token) or tokens[index] == "-" and tonumber(tokens[index + 1]) then
		return colors.numbers
	elseif token == "nil" then
		return colors.null
	elseif token:sub(1, 1) == "{" or token:sub(1, 1) == "}" then
		return colors.var_name
	elseif token:sub(1, 1) == ";" then
		return colors.comment
	elseif token:sub(1, 1) == "\"" then
		return colors.str
	elseif token == "true" or token == "false" then
		return colors.boolean
	elseif operatorsSet[token] then
		return colors.operator
	elseif specialOperatorsSet[token] then
		return colors.spec_operator
	elseif tokens[index + 1] == "?" then
		if cobaltSet[token .. "?"] then
			return colors.cobalt
		end
	elseif token == "?" then
		if tokens[index - 1] then
			if cobaltSet[tokens[index - 1] .. "?"] then
				return colors.cobalt
			end
		end
	elseif token == "-" then
		if cobaltSet[tokens[index - 1] .. "-" .. tokens[index + 1]] then
			return colors.cobalt
		end
	elseif tokens[index - 1] == "-" and tokens[index - 2] then
		if cobaltSet[tokens[index - 2] .. "-" .. token] then
			return colors.cobalt
		end
	elseif tokens[index + 1] == "-" and tokens[index + 2] then
		if cobaltSet[token .. "-" .. tokens[index + 2]] then
			return colors.cobalt
		end
	elseif cobaltSet[token] then
		return colors.cobalt
	end


	local num = 0
	repeat
		num += 1
	until tokens[index - num] ~= " " and tokens[index - num] ~= ""

	if token ~= " " then
		if tokens[index - num] == "var" then
			return colors.var_name
		elseif tokens[index - num] == "function" then
			table.insert(functionNames, token)
			return colors.function_call
		elseif table.find(functionNames, token) then
			return colors.function_call
		end
	end
end

function highlighter.run(source)
	local tokens = {}
	functionNames = {}
	local currentToken = ""

	local inString = false
	local inComment = false
	local inCall = false

	for i = 1, #source do
		local character = source:sub(i, i)

		if inComment then
			if character == "\n" then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""

				inComment = false
			else
				currentToken = currentToken .. character
			end
		elseif inCall then
			if source:sub(i, i) == "}" then
				currentToken ..= "}"
				table.insert(tokens, currentToken)
				--table.insert(tokens, character)
				currentToken = ""

				inCall = false
			else
				currentToken = currentToken .. character
			end
		elseif inString then
			if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
				currentToken = currentToken .. character

				inString = false
			else
				currentToken = currentToken .. character
			end
		else
			if source:sub(i, i) == ";" then
				table.insert(tokens, currentToken)
				currentToken = ";"
				inComment = true
			elseif source:sub(i, i) == "{" then
				table.insert(tokens, currentToken)
				currentToken = "{"
				inCall = true
			elseif character == "\"" then
				table.insert(tokens, currentToken)
				currentToken = character
				inString = character
			elseif operatorsSet[character] then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			elseif character:match("[%w_]") then
				currentToken = currentToken .. character
			else
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			end
		end
	end

	table.insert(tokens, currentToken)

	local highlighted = {}

	for i, v in pairs(tokens) do
		if v == "" then table.remove(tokens, i) end
	end
	for i, token in ipairs(tokens) do
		local highlight = getHighlight(tokens, i)

		if highlight then
			local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

			table.insert(highlighted, syntax)
		else
			table.insert(highlighted, token)
		end
	end

	return table.concat(highlighted)
end

return highlighter