local e = {}

e.format = function(currentProccess, text)
	local cp = ""
	if currentProccess then
		cp = " : " .. tostring(currentProccess)
	end

	return "[compiler]: " .. tostring(text) .. cp .. " : End."
end

return e
