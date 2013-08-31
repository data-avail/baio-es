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
extend = require("util")._extend

_config = null

#uri
#timeout
setConfig = (config) ->
  _config = config

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
  if !Array.isArray(docs)
    done "docs not array"
  if !docs.length
    done(null, [])
    return
  res = ""
  for doc in docs
    obj = { }
    obj[if doc._action then doc._action else "index"] =
    { "_index" : index, "_type" : doc._type, "_id" : doc._id }
    res += JSON.stringify(obj)
    res += "\r\n"
    obj = JSON.parse(JSON.stringify(doc))
    delete obj._id
    delete obj._type
    delete obj._action
    res += JSON.stringify(obj)
    res += "\r\n"
    console.log res
  _r_oper uri : uri, index : index, oper : "_bulk", method : "post", body : res, done

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
  _r_oper uri : opts.uri, index : opts.index, method : "get", done

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
  _r_oper uri : opts.uri, index : opts.index, method : "delete", done

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
  _r_oper uri : opts.uri, index : opts.index, method : "post", body : settings, done

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


#uri
#index
#type
#body
query = (opts, done) ->
  params = extend {}, opts
  params.oper = "_search"
  _r_oper params, (err, data) ->
    if !err
      data = data.hits.hits.map (m) ->
        src = m._source
        if m.highlight
          src._highlight = m.highlight
        src
    done err, data

#uri
#index
#type
#body
count = (opts, done) ->
  params = extend {}, opts
  params.oper = "_count"
  params.body = params.body.query if params.body and params.body.query
  _r_oper params, (err, data) ->
    if !err
      data = count : data.count
    done err, data

# ##Private API##

_r_oper = (params, done) ->
  #uri, index, oper, method, body
  ### uri ###
  opts =
    uri : params.uri
  opts.uri ?= _config.uri
  opts.uri += '/' + params.index
  if params.type
    opts.uri += '/' + params.type
  if params.oper
    opts.uri += '/' + params.oper
  ### body ###
  if typeof params.body == "object"
    opts.json = params.body
  else
    opts.body = params.body
  ### method ###
  opts.method = params.method if params.method
  console.log opts
  req opts, (err, res) ->
    if !err and res.body
      res = res.body
      try
        res = JSON.parse(res) if typeof res == "string"
      catch e
        done res
        return
      if !res.error
        done err, res
      else
        done res.error
    else
      done err

exports.setConfig = setConfig
exports.createIndex = createIndex
exports.deleteIndex = deleteIndex
exports.getIndex = getIndex

exports.copy = copy
exports.bulk = bulk
exports.map = map
exports.bkp = bkp
exports.query = query
exports.count = count

