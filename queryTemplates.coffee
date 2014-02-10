"use strict"

module.exports =
  search :
    req : (opts) ->
      oper : "_search"
      json : opts
    resp : (res) ->
      res
  count :
    req : (opts) ->
      oper : "_count"
      json : opts
    resp : (res) ->
      res.count
