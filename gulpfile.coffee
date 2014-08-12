gulp          = require 'gulp'
del           = require 'del'
coffee        = require 'gulp-coffee'
gutil         = require 'gulp-util'

gulp.task 'clean', (callback) ->
  del ['lib'], callback

gulp.task 'coffee-src', ['clean'], ->
  gulp.src ['src/**/*.coffee']
  .pipe(coffee bare: true).on 'error', gutil.log
  .pipe gulp.dest 'lib'

gulp.task 'build', ['clean', 'coffee-src']
