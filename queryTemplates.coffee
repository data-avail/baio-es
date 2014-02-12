"use strict"

module.exports =
  search :
    opts :
      oper : "_search"
    req : (opts) ->
      json : query : opts
    resp : (res) ->
      res.hits.hits.map((m) ->
        r = m._source
        r._id = m._id
        r
      )
  count :
    opts :
      oper : "_count"
    req : (opts) ->
      json : opts
    resp : (res) ->
      res.count
