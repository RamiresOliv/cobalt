local api = require("src.api")

local metadata = {}
metadata.name = "cobalt"
metadata.version = "1.7.6"
metadata.license = "MIT"
metadata.docs = "https://github.com/RamiresOliv/Cobalt"
metadata.compiler = "Luau"

metadata.constants = function()
	local r = {}
	for i, v in pairs(api.natives) do
        r[i] = v
	end

	r._COMPILER = metadata.compiler
	r._DOCS = metadata.docs
	r._VERSION = metadata.name .. " " .. metadata.version
	return r
end

return metadata
