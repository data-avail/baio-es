"use strict"

module.exports =
  search :
    req : (opts) ->
      oper : "_search"
      json : query : opts
    resp : (res) ->
      console.log res
      res.hits.hits.map((m) ->
        res = m._source
        res._id = m._id
        res
      )
  count :
    req : (opts) ->
      oper : "_count"
      json : opts
    resp : (res) ->
      res.count
