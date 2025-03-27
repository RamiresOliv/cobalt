# Cobalt

_"That programming language"_
Being easy to set up your own commands and edit them.
Plan to be an easy way to control values or just to be simple to get user logical input and receive it's inputs.
This language has started in [Roblox](https://www.roblox.com/games/97398140739060/). Now it's here!

## Lua

You should have lua installed. If not, we have lua 5.4 for you! Located at `bin`
But remember to install it and add it at `PATH` env.
Install from [here](https://www.lua.org/download.html)

## Usage

first of all, you just need to run the cobalt.exe to execute any `.ct` file.
depending on the situation, you may use `cobalt.lua` directly, it will push all the sequence at `src`

**exemple (no return expect):**

```lua
local cobalt = require("cobalt.call") -- path.to.cobalt (cobalt.lua)

local returns = cobalt("(+ 1 1)") -- code as string, epected returns as boolean.
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
print(returns[2]) -- should be nil (because wasn't expected returns)
```

**exemple 2 (return expected):**

```lua
local cobalt = require("cobalt") -- path.to.cobalt (cobalt.lua)

local returns = cobalt("(+ 1 1)", true) -- code as string, epected returns as boolean.
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
print(returns[2]) -- should be 2
```

**exemple 3 (using cobalt files):**

```clj
; my_module.ct
; You can use {%1}, {%2}, {%3} ... for call arguments for the module when called.

(print "Hello {%1} and World from my_module!")
(return "Here is this important string!") ; to return the cool string
(print "Nothing after return's will work.")
```

```lua
local cobalt = require("cobalt") -- path.to.cobalt (cobalt.lua)

local returns = cobalt('(require "my_module.ct" [(prompt "Your name is?")])', true) -- calling module and sending an argument as list
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
print(returns[2]) -- should be "Here is this important string!"
```
