"use strict";
module.exports = {
  search: {
    req: function(opts) {
      return {
        oper: "_search",
        json: {
          query: opts
        }
      };
    },
    resp: function(res) {
      return res.hits.hits.map(function(m) {
        res = m._source;
        res._id = m._id;
        return res;
      });
    }
  },
  count: {
    req: function(opts) {
      return {
        oper: "_count",
        json: opts
      };
    },
    resp: function(res) {
      return res.count;
    }
  }
};
