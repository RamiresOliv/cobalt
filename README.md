# 🔵 Cobalt

_"That one programming language"_<br>
Being open source, make easy to set up your own commands and edit them.<br>
And planned to be an easy way to control values or just to be simple to get user logical input and receive it's inputs.<br>
This language has started in [Roblox](https://www.roblox.com/games/97398140739060/). Now it's here!<br>
Able to, manage http requests, JSON, variables, file system, math and more.

## 🌙 Lua

You should have lua installed. If not, we have lua 5.4 for you! Located at `bin`<br>
But remember to install it and add it at `PATH` env.<br>
Install from [here](https://www.lua.org/download.html)

## 💻 Usage

first of all, you just need to run the cobalt.exe to execute any `.ct` file.<br>
depending on the situation, you may use `cobalt.lua` directly, it will push all the sequence at `src`<br>

if you want to call cobalt, always use the `call.lua` file, and never `main.lua`. Because `main` is there for the executables. And `call` is directly to `src/index.lua`.

#### - Terminal examples:

**example 1.1**
Using the `cobalt` to call for help

```
$ cobalt
> help
all the commands list ...
> cobalt help <commandName>
```

```
$ cobalt
> help function
(function {string} [function/string] ...): nil
- Creates a custom function with a name, being able to be called as (my_function_name [my_arg1] [my_arg2] ...)
---------------------------------------------------------------------------------------------------------------
```

**example 1.2**
Executing cobalt files

```clj
; my_module.ct
; You can use {%1}, {%2}, {%3} ... to call module arguments

(print "Hello {%1} and World from my_module!")
(return "Here is this important string!") ; to return the cool string
(print "Nothing after return's will work.")
```

```
$ cobalt my_module.ct Ramires
Hello Ramires and World from my_module!
Here is this important string!
```

`cobalt my_module.ct arg1 arg2 arg3 ...`

#### - Lua examples:

**example 2 (no return expect):**

```lua
local cobalt = require("cobalt.call") -- path.to.call (call.lua)

local returns = cobalt("(+ 1 1)") -- code as string, epected returns as boolean.
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
print(returns[2]) -- should be nil (because wasn't expected returns)
```

**example 3 (return expected):**

```lua
local cobalt = require("cobalt") -- path.to.call (call.lua)

local returns = cobalt("(+ 1 1)", true) -- code as string, epected returns as boolean.
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
print(returns[2]) -- should be 2
```

**example 4 (using cobalt files):**

```clj
; my_module.ct
; You can use {%1}, {%2}, {%3} ... to call module arguments.

(print "Hello {%1} and World from my_module!")
(return "Here is this important string!") ; to return the cool string
(print "Nothing after return's will work.")
```

```lua
local cobalt = require("cobalt") -- path.to.call (call.lua)

local returns = cobalt('(require "my_module.ct" [(input "Your name is?")])', true) -- calling module and sending an argument as list
-- returns a table
-- [1]: success boolean
-- [2]: the value to be returned (if theres any) or the error reason.
print(returns[1]) -- should be true
print(returns[2]) -- should be "Here is this important string!"
```

**example 5 (bf interpreter in cobalt)**
You can check the file `braincrazy.ct` to check that out

## 🐛 Found bugs?

Report them!<br>
Open an [Issue - bug](https://github.com/RamiresOliv/cobalt/issues/new) let me know!

And please note that, this is a project in development.<br>
Don't be upset if something happen to you.

## Comming

- HTTP-SERVER
- More in depth documentation about
- Expecting more linux compability as executable. (I am not a linux user, sorry)
