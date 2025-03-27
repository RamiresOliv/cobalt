-- bruh
local self = {}

-- really not a copy of references.color
self.colorize = function (text, color)
	local colors = {
		red     = "\27[31m",
		green   = "\27[32m",
		blue    = "\27[34m",
		yellow  = "\27[33m",
		purple  = "\27[35m",
		orange  = "\27[91m",  -- bright red/orange
		cyan    = "\27[36m",
		magenta = "\27[95m",
		black   = "\27[30m",
		white   = "\27[37m",
		gray    = "\27[90m",
		pink    = "\27[95m",
		brown   = "\27[33m",  -- reused yellow for brown
		lime    = "\27[32m",
		navy    = "\27[34m",
		blank   = "\27[0m"    -- reset/no color
	}

	text = tostring(text)
	color = tostring(color)

	local colorCode = colors[color:lower()]
	if not colorCode and color ~= "bold" and color ~= "italic" then
		local clrs = {}
		for k, _ in pairs(colors) do
			table.insert(clrs, k)
		end
		--return false, "[core-terminal][color] invalid color name. Valid names are: " .. table.concat(clrs, ", ") .. "."
		return false
	end

	local formatted
	if color:lower() == "bold" then
		formatted = "\27[1m" .. text .. "\27[0m"
	elseif color:lower() == "italic" then
		formatted = "\27[3m" .. text .. "\27[0m"
	else
		formatted = colorCode .. text .. "\27[0m"
	end

	return formatted
end

return self