(print (color "Attention: this OS is experimental and made in a very old Cobalt version. So expect bugs!" "yellow"))
(print (color "You can use 'exit' to leave this loop or use ctrl+R." "yellow"))
(print "")
(print "Welcome {username}, to Olive-OS")
(print "This is the most cooler OS in the entire Roblox.")
(print "This OS is fully made in Cobalt!")
(print (color "https://ramiresoliv.github.io/Cobalt" "cyan"))

; insane OS init.rbb
(for (inf)
  (var main_os_loop_prompt (prompt {username} {desktopname} (getcd)))
  (var prompt_result (split (get main_os_loop_prompt) (space)))
  (var command (listget (get prompt_result) 1))
  (var args (listrem (get prompt_result) 1))

  (if (== (lower {command}) "exit") 
    (print (str "exited."))
    (break)
  )

  (if (not (nil? (fexists? "root/bin/{command}")))
    (require "root/bin/{command}" (get args))
  else
    (if (not (nil? (fexists? "root/aliases/{command}")))
      (var ata (require "root/aliases/{command}" (get args) true))
      (var _______&&%!r_! (format "root/bin/{1}" (get ata)))
      (require (get _______&&%!r_!) (get args))
    else
      (print (color (str "'{command}' doesn't exists.") red))
    )
  )
)