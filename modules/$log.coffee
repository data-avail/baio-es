"use strict"

exports.log = ->
  args = Array.prototype.slice.call(arguments, 0)
  console.log "--->>>"
  for arg in args
    if arg
      json_arg = if typeof arg == "string" then JSON.parse(arg) else arg
      str_arg  = JSON.stringify(json_arg, null, 2)
      if str_arg.length > 500
        str_arg = str_arg.substring(str_arg, 500) + "..."
    else
      str_arg = arg
    console.log(str_arg)
  console.log "<<<---"
