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

bulk = (opts, docs, done) ->
  if !Array.isArray(docs)
    done "docs not array"
  if !docs.length
    done(null, [])
    return
  res = ""
  for doc in docs
    obj = { }
    index = doc._index
    index ?= opts.index
    index = opts.index_prefix + "." + index if opts.index_prefix
    action = if doc._action then doc._action else (if opts.action then opts.action else "index")
    type = if doc._type then doc._type else opts.type
    obj[action] = _index : index, _type : type, _id : doc._id
    res += JSON.stringify(obj)
    res += "\r\n"
    _doc = extend({}, doc)
    delete _doc._id
    delete _doc._index
    delete _doc._type
    delete _doc._action
    if action != "delete"
      res += JSON.stringify(_doc)
      res += "\r\n"
  oper_opts = extend(extend({}, opts), {uri : opts.uri, index : null, type : null, oper : "_bulk", method : "post", body : res})
  _r_oper oper_opts, done

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
  _r_oper extend(method : "delete", opts), done

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
  _r_oper extend({method : "post", body : settings}, opts), done

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
query = (opts, body, done) ->
  params = extend {body : body}, opts
  params.oper = "_search" if !opts.id
  _r_oper params, done


#uri
#index
#type
#body
count = (opts, done) ->
  params = extend {oper : "_count"}, opts
  params.body = params.body.query if params.body and params.body.query
  _r_oper params, (err, data) ->
    if !err
      data = count : data.count
    done err, data

# ##Private API##

_r_oper = (params, done) ->
  opts =
    uri : params.uri
  opts.uri ?= _config.uri
  index = params.index
  index = params.index_prefix + "." + index if index and params.index_prefix
  if index
    opts.uri += '/' + index
  if params.type
    opts.uri += '/' + params.type
  if params.oper
    opts.uri += '/' + params.oper
  if params.id
    opts.uri += '/' + params.id
  ### body ###
  if typeof params.body == "object"
    opts.json = params.body
  else
    opts.body = params.body
  ### method ###
  opts.method = params.method if params.method

  req opts, (err, res) ->
    if params.debug
      console.log JSON.stringify(opts), err, (if res then JSON.stringify(res.body) else null)
    if !err and res and res.body
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

