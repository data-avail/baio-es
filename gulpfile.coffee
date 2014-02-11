"use strict"

gulp = require "gulp"
gutil = require "gulp-util"
coffee = require "gulp-coffee"

gulp.task "default", ->
  gulp.src("./*.coffee")
  .pipe(coffee({bare: true}).on('error', gutil.log))
  .pipe(gulp.dest("./build/"))