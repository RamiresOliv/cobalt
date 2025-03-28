--- This calls the index function correctly. You should use this function to call index. (index:init)
-- @param code: string - The code as string
-- @param expectReturn: bool - Should return the command result? (i.g math operations commands)
-- @return: anything
return function(code, expectReturn)
	return require("src.index"):init(code, nil, expectReturn or false)
end
-- calls index