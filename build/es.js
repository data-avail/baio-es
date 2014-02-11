var Q, bulk, count, createIndex, extend, fs, getRequestOpts, ioc, parseQueryReq, parseQueryResp, query, queryTemplates, removeIndex, search, setConfig, stripePredefinedOpts, _config, _r;

fs = require("fs");

extend = require("xtend");

Q = require("q");

ioc = require("./ioc");

queryTemplates = require("./queryTemplates");

ioc.register("$http", function() {
  return require("./modules/$http");
});

ioc.register("$log", function() {
  return require("./modules/$log");
});

_config = null;

setConfig = function(config) {
  return _config = config;
};

createIndex = function(opts) {
  if (!opts || !opts.settings) {
    throw new Error("Missed arg: opts.settings");
  }
  opts = extend(opts, {
    method: "post",
    json: opts.settings
  });
  delete opts.settings;
  return _r(opts);
};

removeIndex = function(opts) {
  return _r(extend(opts, {
    method: "delete"
  }));
};

bulk = function(opts, docs) {
  var action, doc, index, obj, res, type, _doc, _i, _len;
  if (Array.isArray(opts)) {
    docs = opts;
    opts = {};
  }
  if (!Array.isArray(docs)) {
    throw new Error("Wrong arg: docs must be array");
  }
  if (_config) {
    opts = extend(_config, opts);
  }
  res = "";
  for (_i = 0, _len = docs.length; _i < _len; _i++) {
    doc = docs[_i];
    obj = {};
    index = doc._index;
    if (index == null) {
      index = opts.index;
    }
    if (opts.index_prefix) {
      index = opts.index_prefix + "." + index;
    }
    action = doc._action ? doc._action : (opts.action ? opts.action : "index");
    type = doc._type ? doc._type : opts.type;
    obj[action] = {
      _index: index,
      _type: type,
      _id: doc._id
    };
    res += JSON.stringify(obj);
    res += "\r\n";
    _doc = extend({}, doc);
    delete _doc._id;
    delete _doc._index;
    delete _doc._type;
    delete _doc._action;
    if (action !== "delete") {
      res += JSON.stringify(_doc);
      res += "\r\n";
    }
  }
  opts = extend(opts, {
    index: null,
    type: null,
    oper: "_bulk",
    method: "post",
    body: res
  });
  return _r(opts);
};

search = function(opts) {
  return query("search", opts);
};

count = function(opts) {
  return query("count", opts);
};

query = function(name, opts) {
  var parsedOpts;
  parsedOpts = parseQueryReq(name, opts);
  console.log(JSON.stringify(parsedOpts, null, 2));
  return _r(parsedOpts).then(function(res) {
    return Q.fcall(function() {
      return parseQueryResp(name, res);
    });
  });
};

parseQueryResp = function(name, res) {
  var tmpl;
  tmpl = queryTemplates[name];
  if (!tmpl) {
    throw new Error("Argument out of range: query template [" + name + "] not found");
  }
  if (tmpl.parent) {
    res = parseQueryResp(tmpl.parent, res);
  }
  res = tmpl.resp(res);
  return res;
};

parseQueryReq = function(name, opts) {
  var res, stripedOpts, tmpl;
  tmpl = queryTemplates[name];
  if (!tmpl) {
    throw new Error("Argument out of range: query template [" + name + "] not found");
  }
  stripedOpts = stripePredefinedOpts(opts);
  res = tmpl.req(stripedOpts.custom);
  if (tmpl.parent) {
    res = parseQueryReq(tmpl.parent, res);
  }
  return res;
};

stripePredefinedOpts = function(opts) {
  var custom, i, predefined, _i, _len, _ref;
  predefined = {};
  custom = extend(opts, {});
  _ref = ["index", "type", "id", "oper", "body", "json"];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    i = _ref[_i];
    if (opts[i]) {
      predefined[i] = opts[i];
      delete custom[i];
    }
  }
  return {
    predefined: predefined,
    custom: custom
  };
};

_r = function(params) {
  var log, opts, promise;
  opts = getRequestOpts(params);
  log = ioc.get("$log").log;
  promise = ioc.get("$http").request(opts);
  promise.then(function(res) {
    return log(null, res, opts);
  }, function(err) {
    return log(err, null, opts);
  });
  return promise;
};

getRequestOpts = function(params) {
  var index, opts;
  opts = extend({}, params);
  if (_config) {
    opts = extend(_config, opts);
  }
  index = opts.index;
  if (index && opts.index_prefix) {
    index = opts.index_prefix + "." + index;
  }
  if (index) {
    opts.uri += '/' + index;
  }
  if (opts.type) {
    opts.uri += '/' + opts.type;
  }
  if (opts.oper) {
    opts.uri += '/' + opts.oper;
  }
  if (params.id) {
    opts.uri += '/' + opts.id;
  }
  delete opts.index;
  delete opts.type;
  delete opts.oper;
  if (!opts.body) {
    delete opts.body;
  }
  if (!opts.json) {
    delete opts.json;
  }
  if (opts.method == null) {
    opts.method = "get";
  }
  return opts;
};

exports.injector = function(name, inject) {
  if (inject === void 0) {
    return ioc.get(name);
  } else {
    return ioc.register(name, inject);
  }
};

exports.setConfig = setConfig;

exports.createIndex = createIndex;

exports.removeIndex = removeIndex;

exports.bulk = bulk;

exports.query = query;

exports.search = search;

exports.count = count;

exports.queryTemplates = queryTemplates;
