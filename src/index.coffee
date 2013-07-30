###
Module dependencies.
###

{EventEmitter} = require 'events'
Route = require("./route")
methods = require("methods")
debug = require("debug")("express:router")
parse = require("connect").utils.parseUrl

flatten = (arr, ret) ->
  ret = ret or []
  len = arr.length
  i = 0

  while i < len
    if Array.isArray(arr[i])
      flatten arr[i], ret
    else
      ret.push arr[i]
    ++i
  ret

###
Expose `Router` constructor.
###

###
Initialize a new `Router` with the given `options`.

@param {Object} options
@api private
###
Router = (options) ->
  options = options or {}
  self = this
  @map = {}
  @namedMap = {}
  @params = {}
  @_params = []
  @caseSensitive = options.caseSensitive
  @strict = options.strict
  @middleware = router = (req, res, next) ->
    self._dispatch req, res, next
  return @

exports = module.exports = Router

for k, func of EventEmitter.prototype
  console.log 'K : ', k
  Router.prototype[k] = func

###
Register a param callback `fn` for the given `name`.

@param {String|Function} name
@param {Function} fn
@return {Router} for chaining
@api public
###
Router::param = (name, fn) ->

  # param logic
  if "function" is typeof name
    @_params.push name
    return

  # apply param functions
  params = @_params
  len = params.length
  ret = undefined
  i = 0

  while i < len
    fn = ret  if ret = params[i](name, fn)
    ++i

  # ensure we end up with a
  # middleware function
  throw new Error("invalid param() call for " + name + ", got " + fn)  unless "function" is typeof fn
  (@params[name] = @params[name] or []).push fn
  this


###
Route dispatcher aka the route "middleware".

@param {IncomingMessage} req
@param {ServerResponse} res
@param {Function} next
@api private
###
Router::_dispatch = (req, res, next) ->
  params = @params
  self = this
  debug "dispatching %s %s (%s)", req.method, req.url, req.originalUrl

  # route dispatch
  (pass = (i, err) ->

    # match next route
    nextRoute = (err) ->
      pass req._route_index + 1, err

    # match route

    # no route

    # we have a route
    # start at param 0

    # param callbacks
    param = (err) ->
      paramIndex = 0
      key = keys[i++]
      paramVal = key and req.params[key.name]
      paramCallbacks = key and params[key.name]
      try
        if "route" is err
          nextRoute()
        else if err
          i = 0
          callbacks err
        else if paramCallbacks and `undefined` isnt paramVal
          paramCallback()
        else if key
          param()
        else
          i = 0
          callbacks()
      catch err
        param err

    # single param callbacks
    paramCallback = (err) ->
      fn = paramCallbacks[paramIndex++]
      return param(err)  if err or not fn
      fn req, res, paramCallback, paramVal, key.name

    # invoke route callbacks
    callbacks = (err) ->
      fn = route.callbacks[i++]
      try
        if "route" is err
          nextRoute()
        else if err and fn
          return callbacks(err)  if fn.length < 4
          fn err, req, res, callbacks
        else if fn
          return fn(req, res, callbacks)  if fn.length < 4
          callbacks()
        else
          nextRoute err
      catch err
        callbacks err
    paramCallbacks = undefined
    paramIndex = 0
    paramVal = undefined
    route = undefined
    keys = undefined
    key = undefined
    req.route = route = self.matchRequest(req, i)
    return next(err)  unless route
    debug "matched %s %s", route.method, route.path
    req.params = route.params
    keys = route.keys
    i = 0
    param err
  ) 0

Router::reverse = (name) ->
  url = @namedMap[name]

  url = url.replace /(\/:\w+\??)/g, (url, c) ->
    c = c.replace(/[/:?]/g, "")
    (if obj[c] then "/" + obj[c] else "")
  url

###
Attempt to match a route for `req`
with optional starting index of `i`
defaulting to 0.

@param {IncomingMessage} req
@param {Number} i
@return {Route}
@api private
###
Router::matchRequest = (req, i, head) ->
  method = req.method.toLowerCase()
  url = parse(req)
  path = url.pathname
  routes = @map
  i = i or 0
  route = undefined

  # HEAD support
  if not head and "head" is method
    route = @matchRequest(req, i, true)
    return route  if route
    method = "get"

  # routes for this method
  if routes = routes[method]

    # matching routes
    len = routes.length

    while i < len
      route = routes[i]
      if route.match(path)
        req._route_index = i
        return route
      ++i


###
Attempt to match a route for `method`
and `url` with optional starting
index of `i` defaulting to 0.

@param {String} method
@param {String} url
@param {Number} i
@return {Route}
@api private
###
Router::match = (method, url, i, head) ->
  req =
    method: method
    url: url

  @matchRequest req, i, head


###
Route `method`, `path`, and one or more callbacks.

@param {String} method
@param {String} path
@param {Function} callback...
@return {Router} for chaining
@api private
###
Router::route = (method, path, name, callbacks...) ->
  method = method.toLowerCase()
  callbacks = flatten callbacks
  if typeof name is 'function'
    callbacks = [name].concat callbacks
    name = undefined

  # ensure path was given
  throw new Error("Router#" + method + "() requires a path")  unless path

  # ensure all callbacks are functions
  callbacks.forEach (fn, i) ->
    return  if "function" is typeof fn
    type = {}.toString.call(fn)
    msg = "." + method + "() requires callback functions but got a " + type
    throw new Error(msg)


  # create the route
  debug "defined %s %s", method, path
  route = new Route(method, path, name, callbacks,
    sensitive: @caseSensitive
    strict: @strict
  )

  # add it
  (@map[method] = @map[method] or []).push route
  if name?
    @namedMap[name] = path
  @emit 'add-route', route
  this

methods.forEach (method) ->
  Router::[method] = (path) ->
    args = [method].concat([].slice.call(arguments))
    @route.apply @, args
    this
