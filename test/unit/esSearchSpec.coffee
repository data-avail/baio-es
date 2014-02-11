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

    it "http should be called with defined params", ->
      es.count(term : user : "baio").then (res) ->
        res.should.equal(2)

  describe.skip "custom query template", ->

    beforeEach ->

      es.queryTemplates.count_bool_must =
        parent : "count"
        req : (opts) ->
          bool : must : opts.map (m) -> term : m
        resp: (res) ->
          res

      es.queryTemplates.is_user_name_exists =
        parent : "count_bool_must"
        req : (opts) ->
          user : "baio", name : opts.name
        resp: (res) ->
          res != 0

    beforeEach ->
      es.query("is_baio_name_exists", name : "name 1")

    it "http should be called with defined params", ->
      assert = require("../fixtures/http-requests/count-user.json")
      requestStub.calledOnce.should.be.truthy
      requestStub.args[0][0].should.eql assert