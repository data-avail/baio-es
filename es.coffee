#baio-es
#
#http://github.com/data-avail/baio-es
#
#2014 Max Putilov, Data-Avail
#
#Baio-es may be freely distributed under the MIT license.
#
#Elastic search basic operations.
#

fs = require "fs"
extend = require "xtend"
Q = require "q"

ioc = require "./ioc"
queryTemplates = require "./queryTemplates"

ioc.register "$http", -> require "./modules/$http"
ioc.register "$log", -> require "./modules/$log"


_config = null

#**setConfig (opts)**
#
# Initialize config (optional)
#
#@parameters
#
# `config {Object}` contains fields
#
# + `config.uri {uri}` - connections string to elsatic search service
# + `config.index` - elastic search default index
# + `config.type` - elastic search default type
# + `config.index_prefix` - compose `index` name using this prefix, such as `index_prefix.index`
#
#Each method accepts opts argument, which could contain the same config options : uri, index, type
#(among other special params for the method), in which case config properties defined via `setConfig` will be
#overriden for the method call. Otherwice `opts` from this method will be used.
setConfig = (config) ->
  _config = config

#**createIndex (opts)**
#
# Create new elastic search index.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `config` proerties, see `setConfig`
# + `opts.settings {object}` - index [settings](http://www.elasticsearch.org/guide/reference/api/index_/)
#
#@returns Q promise

createIndex = (opts) ->
  if !opts or !opts.settings
    throw new Error("Missed arg: opts.settings")
  opts = extend(opts, {method : "post", json : opts.settings})
  delete opts.settings
  _r opts


#**removeIndex (opts)**
#
# Delete elastic search index.
#
#@parameters
#
# `opts {Object}` contains fields
#
# + `opts.uri {uri}` - connections string to elsatic search service
# + `opts.index {string}` - name of the index
#
#@returns Q promise

removeIndex = (opts) ->
  _r extend(opts, method : "delete")

# ##bulk API##

#**bulk = (opts)**
#
# Perfoms [bulk](http://www.elasticsearch.org/guide/reference/api/bulk/) operation.
#
#@parameters
#
# `opts {Object}` contains fields, optional
#
# + `uri {uri}` - connections string to elsatic search service
# + `index {string}` - name of the index
# + see also `setConfig`
# + `data {array[object]}`
#     + `_id` - id of es document, optional
#     + `_index` - index of es document, required (also could be be defined in opts.index or via `setConfig`)
#     + `_type` - type of es document, required (also could be be defined in opts.type or via `setConfig`)
#     + `_action` - bulk item action, default `index`, optional
#
bulk = (opts, docs) ->
  if Array.isArray(opts)
    docs = opts
    opts = {}
  if !Array.isArray(docs)
    throw new Error("Wrong arg: docs must be array")
  if _config
    opts = extend _config, opts
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
  opts = extend(opts, {index : null, type : null, oper : "_bulk", method : "post", body : res})
  _r opts

# ##Query API##

#**search (opts)**
#
# perfoms [query-dsl](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html) request
# and returns `source` data
#
#@parameters
#
# `opts {Object}`
#
#  + see `setConfig` opts
#  + any `query-dsl` formatted request (without `query` container block)
#
# returns Q promise to find data
search = (opts) ->
  return query "search", opts

#**count (opts)**
#
# perfoms [count](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-count.html) query
# and returns documents count
#
#@parameters
#
# `opts {Object}`
#
#  + see `setConfig` opts
#  + any `count-api` formatted request
#
# returns Q promise to find documents count
count = (opts) ->
  return query "count", opts


#**query (opts)**
#
# Exceute custom query.
# Custom queries could be added via `queryTemplates` property.
# Library already contains 2 custom queries - `search` and `count`, see `queryTemplates` file.
#
# See also redme `custom queries` section
#
# returns Q promise to return result
query = (name, opts) ->
  parsedOpts = parseQueryReq name, opts
  _r(parsedOpts).then (res) -> Q.fcall -> parseQueryResp name, res

# ##Private API##

parseQueryReq = (name, opts) ->
  #get query template
  tmpl = queryTemplates[name]
  if !tmpl
    throw new Error "Argument out of range: query template [#{name}] not found"
  #stripe predfefined options
  stripedOpts = stripePredefinedOpts(opts)
  ropts = stripedOpts.custom
  res = tmpl.req ropts
  if tmpl.parent
    res = parseQueryReq(tmpl.parent, res)
  if tmpl.opts
    res = extend tmpl.opts, res
  res



parseQueryResp = (name, res) ->
  #get query template
  tmpl = queryTemplates[name]
  if !tmpl
    throw new Error "Argument out of range: query template [#{name}] not found"
  if tmpl.parent
    res = parseQueryResp(tmpl.parent, res)
  res = tmpl.resp res
  return res


stripePredefinedOpts = (opts) ->
  predefined = {}
  custom = extend opts, {}
  for i in ["index", "type", "id", "oper", "body",  "json", "action"]
    if opts[i]
      predefined[i] = opts[i]
      delete custom[i]
  predefined : predefined
  custom : custom

_r = (params) ->
  deferred = Q.defer()
  opts = getRequestOpts params
  log = ioc.get("$log").log
  ioc.get("$http").request(opts).then (res) ->
    log null, res, opts
    if !res
      deferred.reject(error : "Server returns empty result, possible reason - server not runned")
    else
      deferred.resolve(res)
  ,(err) ->
    log err, null, opts
    deferred.resolve(err)
  deferred.promise

getRequestOpts = (params) ->
  opts = extend {}, params
  if _config
    opts = extend _config, opts
  index = opts.index
  index = opts.index_prefix + "." + index if index and opts.index_prefix
  if index
    opts.uri += '/' + index
  if opts.type
    opts.uri += '/' + opts.type
  if opts.oper
    opts.uri += '/' + opts.oper
  if params.id
    opts.uri += '/' + opts.id
  delete opts.index
  delete opts.type
  delete opts.oper
  delete opts.index_prefix
  if !opts.body
    delete opts.body
  if !opts.json
    delete opts.json
  opts.method ?= "get"
  return opts

exports.injector = (name, inject) ->
  if inject == undefined
    return ioc.get name
  else
    ioc.register name, inject

exports.setConfig = setConfig
exports.createIndex = createIndex
exports.removeIndex = removeIndex
exports.bulk = bulk
exports.query = query
exports.search = search
exports.count = count
exports.queryTemplates = queryTemplates
