"use strict"

es = require "../../es"
should = require "should"
require("mocha-as-promised")()

describe "query results tests", ->

  resultStub = null

  beforeEach ->
    #Make sure, elastic on port 1111 not runned! ^_^
    es.setConfig uri : "http://localhost:1111", index : "stuff"

  beforeEach ->
    http =
      request : ->
        then : (func) -> func(resultStub)
    es.injector("$http", http)

  describe "search user", ->

    beforeEach ->
      resultStub = require("../fixtures/server-results/user-search-result.json")

    it "should return predefined results", ->
      es.search(term : user : "baio").then (res) ->
        console.log
        res.should.have.lengthOf(2)
        res[0]._id.should.be.ok
        res[1]._id.should.be.ok
        res[0].user.should.eql "baio"
        res[1].user.should.eql "baio"
        res[0].name.should.eql "name 1"
        res[1].name.should.eql "name 2"

  describe "count with search", ->

    beforeEach ->
      resultStub = require("../fixtures/server-results/user-count-result.json")

    it "should return predefined results", ->
      es.count(term : user : "baio").then (res) ->
        res.should.equal(2)

  describe "custom query template", ->

    beforeEach ->
      resultStub = require("../fixtures/server-results/user-count-result-1.json")
      es.queryTemplates.count_bool_must =
        parent : "count"
        req : (opts) ->
          bool : must :  (p for own p of opts).map (p) ->
            r = term : {}; r.term[p] = opts[p]; r;
        resp: (res) ->
          res

    it "should return predefined results", ->
      es.query("count_bool_must", user : "baio").then (res) ->
        res.should.equal(1)


    describe "extend custom query template", ->

      beforeEach ->
        es.queryTemplates.is_user_name_exists =
          parent : "count_bool_must"
          req : (opts) ->
            user : "baio", name : opts.name
          resp: (res) ->
            res != 0

        es.query("is_user_name_exists", name : "name 1")

      it "user should exists", ->
        es.query("is_user_name_exists", name : "name 1").then (res) ->
          res.should.truthy
