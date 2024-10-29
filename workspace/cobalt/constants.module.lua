local language = require(script.Parent.language)
return function()
	local r = {}
	for i, v in require(script.Parent.types).constants do
		if typeof(v) == "Instance" and v:IsA("ValueBase") then
			r[i] = v.Value
		else
			r[i] = v
		end
	end

	r._COMPILER = language.compiler
	r._DOCS = language.docs
	r._VERSION = language.name .. " " .. language.version
	return r
end
