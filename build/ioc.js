"use strict";
var container, dependable;

dependable = require("dependable");

container = dependable.container();

exports.register = container.register;

exports.get = container.get;
