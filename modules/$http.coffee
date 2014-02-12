"use strict"
req = require "request"
Q = require "q"

#uri, method, body
exports.request = (opts) ->
  deferred = Q.defer()
  req opts, (err, rsp, body) ->
    deferred.resolve(body)
  return deferred.promise
