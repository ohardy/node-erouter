# Cakefile

{spawn, exec} = require 'child_process'

removeJS = (callback) ->
  exec 'rm -fr lib/', (err, stdout, stderr) ->
    throw new Error(err) if err
    callback() if callback

_build = (watch) ->
  (options, callback) ->
    if watch
      watch2 = '-w -p'
    else
      watch2 = ''

    exec "mkdir -p lib", (err, stdout, stderr) ->
      throw new Error(err) if err
      params = ['-c', '-b']
      if watch
        params.push '-w'
      params = params.concat ['-o', 'lib', 'src']
      coffee = spawn 'coffee', params
      coffee.stdout.on 'data', (data) ->
        console.log data.toString().trim()
      coffee.stdout.on 'end', ->
        callback() if callback?
      # exec cmd, (err, stdout, stderr) ->
        # throw new Error(err) if err
        # callback() if callback

build = _build false

watch = _build true

cov = (callback) ->
  exec "jscoverage --no-highlight lib lib-cov", (err, output) ->
    exec "NODE_ENV=test FORM_COV=1
      mocha
      --compilers coffee:coffee-script
      --require coffee-script
      --require should
      -R html-cov
      --ui bdd
      --colors > coverage.html
    ", (err, output) ->
      process.stdout.write output
      throw err if err

test = (callback) ->
  exec "NODE_ENV=test
    ./node_modules/.bin/mocha
    --compilers coffee:coffee-script
    --require coffee-script
    --require should
    -R spec
    --ui bdd
    --colors
  ", (err, output) ->
    process.stdout.write output
    throw err if err

publish = (callback = console.log) ->
  build ->
    exec 'npm publish', (err, stdout) ->
      callback(stdout)

task 'build', 'Build lib from src', build
task 'watch', 'Build and watch lib from src',       -> watch()
task 'cov', 'Coverage',                   -> cov()
task 'test', 'Test project',              -> test()
task 'publish', 'Publish project to npm', -> publish()
