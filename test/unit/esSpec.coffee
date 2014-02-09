es = require "../../es"
Q = require "q"
fs = require "fs"

require("mocha-as-promised")()

describe "test elastic search functions", ->

  @timeout(5000)

  it "promises should work", ->
    opts = uri : "http://localhost:9200", index : "sets", settingsPath : "test/fixtures/sets-index.json"
    es.createIndex(opts).then ->
      should.be.ok





