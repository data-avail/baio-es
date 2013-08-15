#Baio-mongo.js 1.0.2
#
#http://github.com/data-avail/baio-es
#
#2013 Max Putilov, Data-Avail
#
#Baio-es may be freely distributed under the MIT license.
#
#Elastic search basic operations.

async = require "async"
fs = require "fs"
req = require "request"

# ##bulk API##

#**bulk = (uri, index, docs, done)**
#
# Perfoms [bulk](http://www.elasticsearch.org/guide/reference/api/bulk/) elastic search opertayion.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `uri {uri}` - connections string to elsatic search service
# + `index {string}` - name of the index
# + `data {array[object]}`
#     + `_id` - id of es document
#     + `_type` - type of es document
#

bulk = (uri, index, docs, done) ->
  if !docs.length
    done(null, [])
    return
  res = ""
  for doc in docs
    obj = { "index" : { "_index" : index, "_type" : doc._type, "_id" : doc._id } }
    res += JSON.stringify(obj)
    res += "\r\n"
    obj = JSON.parse(JSON.stringify(doc))
    delete obj._id
    delete obj._type
    res += JSON.stringify(obj)
    res += "\r\n"
  _r_oper uri, index, "_bulk", "post", res, done

map = (uri, fromIndex, toIndex, docsCount, map, done) ->
  docsCount ?= 10000
  req.get uri : "#{uri}/#{fromIndex}/_search", qs : {size : docsCount}, (err, res) ->
    if !err
      j = JSON.parse(res.body)
      j = j.hits.hits.map (m) -> map m
      bulk uri, toIndex, j, done
    else
      done err

copy = (uri, fromIndex, toIndex, done) ->
  map uri, fromIndex, toIndex, null, ((m) -> m), done


#**getIndex (opts)**
#
# Get elastic search index.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `opts.uri {uri}` - connections string to elsatic search service
# + `opts.index {string}` - name of the index

getIndex = (opts, done) ->
  _r uri : opts.uri, opts.index, "get", null, done


#**deleteIndex (opts)**
#
# Delete elastic search index.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `opts.uri {uri}` - connections string to elsatic search service
# + `opts.index {string}` - name of the index

deleteIndex = (opts, done) ->
  _r opts.uri, opts.index, "delete", null, done

#**createIndex (opts)**
#
# Create new elastic search index.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `opts.uri {uri}` - connections string to elsatic search service
# + `opts.index {string}` - name of the index
# + `opts.settings {object}` - index [settings](http://www.elasticsearch.org/guide/reference/api/index_/)
# + `opts.settingsPath {string}` - path to file with index settings
# Either `settings` or `settingsPath` must be presented.

createIndex = (opts, done) ->
  settings = opts.settings
  if !settings
    settings = JSON.parse fs.readFileSync opts.settingsPath, "utf-8"
  _r opts.uri, opts.index, "post", settings, done

#**bkp (opts)**
#
# Copy data from one index to another.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `to {object}` - index to which data will be copied, see `createIndex`
# + `batchSize {int}` - number of the items which will be copied from `from` to `to` index at once
# + `from {string}` - name of the index from which data will be copied
#
#@worflow :
# + delete `to` index
# + create `to` index, see `createIndex`
# + copy data from `from` to `to`

bkp = (opts, done) ->
  async.waterfall [
    (ck) -> deleteIndex opts, ck
    (ck) -> createIndex opts, ck
    (ck) -> copy opts, ck
  ], done


query = (uri, index, q, done) ->
  req.post uri : "#{uri}/#{index}/_search", body : JSON.stringify(q), (err, res) ->
    if !err
      done null, JSON.parse(res.body).hits.hits.map (m) -> m._source
    else
      done err

# ##Private API##
_r = (uri, index, method, body, done) ->
  _r_oper uri, index, null, method, body, done

_r_oper = (uri, index, oper, method, body, done) ->
  opts = uri : "#{uri}/#{index}", method: method
  opts.uri += "/" + oper if oper
  if typeof body == "string"
    opts.body = body
  else if typeof body == "object"
    opts.json = body

  req opts, (err, res) ->
    err = res.body if res.body.error
    if !err
      res = if res.body and typeof res.body == "string" then JSON.parse res.body else res.body
      done err, res
    else
      done err

exports.createIndex = createIndex
exports.deleteIndex = deleteIndex
exports.getIndex = getIndex

exports.copy = copy
exports.bulk = bulk
exports.map = map
exports.bkp = bkp
exports.query = query

