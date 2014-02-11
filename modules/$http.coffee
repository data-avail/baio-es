"use strict"
req = require "request"
Q = require "q"

#uri, method, body
exports.request = (opts) ->
  Q.denodeify(req)(opts)
  .then (res) ->
    if res.body
      JSON.parse(res.body)
