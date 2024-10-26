# Cobalt - language

A simple programming language, with a complex syntax made fully with Luau.
Made in Roblox Studio.

## Features:

- Free HTTP handling, _(post & get)_
- Math
- Functions
- A friendly interface
- Manual in-game
- Open terminal
- Database _(comming soon)_
- Autorun _(comming soon)_
- Much more!

---

### Roblox Experience:

https://www.roblox.com/games/97398140739060/Cobalt

You only need Roblox installed in your computer. After that, you can "run" cobalt :D
Only by entering in the experience and giving a like, helps me a lot!
This code is open-source and free to use, but it's protected by a [MIT license](./LICENSE).
This language at any circumstance would **never be sold by any price**
You can't pay for cobalt use or even sell in any marketplace.

This all it's a project which I am doing solo. So please, if you liked, make sure to share :)

```clojure
(var get (http-get "http://api.open-notify.org/iss-now.json"))
(var cords (listget {get} 3)) ; change this number to 1 at 3 if you are getting errors, this is a iss-now.json issue.
(print (format "current ISS, latitude: {1} and longitude: {2}" (listget {cords} 1) (listget {cords} 2)))
```
