es = require "../../es"
should = require "should"
sinon = require "sinon"
require("mocha-as-promised")()

describe "test elastic search functions", ->

  beforeEach ->
    #Make sure, elastic on port 1111 not runned! ^_^
    es.setConfig uri : "http://localhost:1111", index : "stuff"

  describe "connect to unexitent server", ->

    it "connection should be refused", ->
      opts = settings : require("../fixtures/stuff-index.json")
      es.createIndex(opts).fail (err) ->
        err.error.should.match /Server returns empty result/

  describe "crud on stuff-index", ->

    requestStub = null

    beforeEach ->
      requestStub = sinon.stub().returns(then : (func) -> func({hits : {hits : []}}))
      http =
        request : requestStub
      es.injector("$http", http)

    describe "create index", ->

      describe "missed settings param", ->

        it "should throw error", ->
          ( ->  es.createIndex(settings1 : {}))
          .should.throw(/Missed arg/)

      describe "with defined params", ->

        beforeEach ->
          es.createIndex(settings : require("../fixtures/stuff-index.json"))

        it "http should be called with defined params", ->
          assert = require("../fixtures/http-requests/create-stuff-index.json")
          requestStub.calledOnce.should.be.truthy
          requestStub.args[0][0].should.eql assert

    describe "remove index", ->

      beforeEach ->
        opts = index : "stuff-index"
        es.removeIndex(opts)

      it "http should be called with defined params", ->
        assert = require("../fixtures/http-requests/delete-stuff-index.json")
        requestStub.calledOnce.should.be.truthy
        delete assert.json
        requestStub.args[0][0].should.eql assert

    describe "bulk insert", ->

      beforeEach ->
        es.bulk(require("../fixtures/stuff-bulk.json").docs)

      it "http should be called with defined params", ->
        assert = require("../fixtures/http-requests/stuff-bulk.json")
        requestStub.calledOnce.should.be.truthy
        requestStub.args[0][0].should.eql assert

    describe "search", ->

      beforeEach ->
        es.search(term : user : "baio")

      it "http should be called with defined params", ->
        assert = require("../fixtures/http-requests/search-user.json")
        requestStub.calledOnce.should.be.truthy
        requestStub.args[0][0].should.eql assert


    describe "count by search", ->

      beforeEach ->
        es.count(term : user : "baio")

      it "http should be called with defined params", ->
        assert = require("../fixtures/http-requests/count-user.json")
        requestStub.calledOnce.should.be.truthy
        requestStub.args[0][0].should.eql assert

