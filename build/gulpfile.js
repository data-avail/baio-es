"use strict";
var coffee, gulp, gutil;

gulp = require("gulp");

gutil = require("gulp-util");

coffee = require("gulp-coffee");

gulp.task("default", function() {
  return gulp.src("./*.coffee").pipe(coffee({
    bare: true
  }).on('error', gutil.log)).pipe(gulp.dest("./build/"));
});
