local language = require("src.language")
local types = require("src.types")
return function()
	local r = {}
	for i, v in pairs(types.natives) do
        r[i] = v
	end

	r._COMPILER = language.compiler
	r._DOCS = language.docs
	r._VERSION = language.name .. " " .. language.version
	return r
end
