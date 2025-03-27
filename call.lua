return function(code, expectReturn)
	return require("src.index"):init(code, nil, expectReturn or false)
end
-- calls index