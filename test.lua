local cobalt = require("call") -- path.to.cobalt (cobalt.lua)

local returns = cobalt('(require "my_module.ct" [(prompt "Your name is?")])', true) -- calling module and sending an argument
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
--print(returns[2]) -- should be 2