"use strict"
require("mocha-as-promised")()
Q = require "q"

after ->
  #give chance to log output
  Q.delay(100)
