return {
[[(if (== (exists? couting.txt) false)
	(mkfile . couting.txt "file created!") ; creates a file (mkfile path name content)
)

(for (prompt "times?") i
	(delay 0)
	(edit couting.txt {i}) ; edits a file (mkfile path+name content)
)

(print (format "final file read: {1}" (read couting.txt)))
]],
[[(function comparative value
  (return (== (type {value}) "string"))
)

(var myList
  [ 
    1,
    2,
    "This is a string",
    "123",
    "String!",
    nil,
    true,
    [1,2,3,4,5,"abcd!!!"]
  ]
)

(print (filter {myList} comparative)) ; ["This is a string", "String!"]
]],[[(function worker
  (var input (prompt "Try guess my random number:"))
  (var correct (random 1 5))
  (if (== {input} {correct})
    (print (colorize "You are right!! Good job!" "green"))
  else
    (print (colorize "No! Wrong number, try again!" "red"))
    (worker)
  )
)
(worker)
]],[[(clear)
(var normalABC [])
(for (alphabet 26) i2 v2 (var r (random 11 99)) (var g (random 11 99)) (var b (random 11 99)) (var normalABC (listadd (get normalABC) (format "<font color='#{1}{2}{3}'>{v2}</font>" (get r) (get g) (get b)))) (print (get normalABC)))
]],[[
(var string "Hello big world.")
(var r [])

(for (split {string}) i v
  (var r (listadd (get r) (replace {v} "%." " ")))
)
(print (get r)) ; ["Hello", "big", "world"]
]],[[(var startTick (tick))
(delay 5)
(var result (/ (floor (* (- (tick) {startTick}) 100)) 100))
(print (format "Done. Result: {1}" (round {result})))
]],[[(for (readdir root) i v
  (if (ends? {v} /)
      (println "{v}:" (readdir (format "root/{1}" (crop {v} 1 -2))))
  )
)
]],[[(print "sup.")
]],[[
(var get (http-get "http://api.open-notify.org/iss-now.json"))
(var cords (listget {get} 3)) ; change this number to 1 at 3 if you are getting errors, this is a iss-now.json issue.
(print (format "current ISS, latitude: {1} and longitude: {2}" (listget {cords} 1) (listget {cords} 2)))
]],[[
(var body (object "message" "Hello World!"))

(var post (http-post "https://postman-echo.com/post" {body}))
(print {post})
]]
}
