
es = require "./es"
should = require "should"

config =
  uri : process.env.ES_URI
  index: "test"
  settings:
      "mappings":
        "_default_":
          "properties":
            "val":
              "fields":
                "val":
                  "index": "not_analyzed",
                  "type": "string"


opts =
  uri: config.uri
  index:  config.index
  settings : config.settings

###
describe "elastic basic operations", ->


  it "index: create / get / delete", (done)->

    opts =
      uri: config.uri
      index:  config.index
      settings : config.settings


    es.createIndex "test", opts, (err, res) ->
      should.not.exist err
      item.should.exist res
      #item.should.have.keys "name", "pass", "id"
      done()
###

createIndex = (done) ->
  es.createIndex opts, (err, res) ->
    should.not.exist err
    should.exist res
    done err, res
    #item.should.have.keys "name", "pass", "id"

deleteIndex = (done) ->
  es.deleteIndex opts, (err, res) ->
    should.not.exist err
    should.exist res
    done err, res

createIndex ->
  deleteIndex ->