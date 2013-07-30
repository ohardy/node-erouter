
###
Module dependencies.
###

###
Expose `Route`.
###

pathRegexp = (path, keys, sensitive, strict) ->
  return path  if path instanceof RegExp
  path = "(" + path.join("|") + ")"  if Array.isArray(path)
  path = path.concat((if strict then "" else "/?")).replace(/\/\(/g, "(?:/").replace(/(\/)?(\.)?:(\w+)(?:(\(.*?\)))?(\?)?(\*)?/g, (_, slash, format, key, capture, optional, star) ->
    keys.push
      name: key
      optional: !!optional

    slash = slash or ""
    "" + ((if optional then "" else slash)) + "(?:" + ((if optional then slash else "")) + (format or "") + (capture or (format and "([^/.]+?)" or "([^/]+?)")) + ")" + (optional or "") + ((if star then "(/*)?" else ""))
  ).replace(/([\/.])/g, "\\$1").replace(/\*/g, "(.*)")
  new RegExp("^" + path + "$", (if sensitive then "" else "i"))

###
Initialize `Route` with the given HTTP `method`, `path`,
and an array of `callbacks` and `options`.

Options:

- `sensitive`    enable case-sensitive routes
- `strict`       enable strict matching for trailing slashes

@param {String} method
@param {String} path
@param {Array} callbacks
@param {Object} options.
@api private
###
Route = (method, path, name, callbacks, options) ->
  options = options or {}
  @path = path
  @name = name
  @method = method
  @callbacks = callbacks
  @regexp = pathRegexp(path, @keys = [], options.sensitive, options.strict)
  return @

module.exports = Route

###
Check if this route matches `path`, if so
populate `.params`.

@param {String} path
@return {Boolean}
@api private
###
Route::match = (path) ->
  keys = @keys
  params = @params = []
  m = @regexp.exec(path)
  return false  unless m
  i = 1
  len = m.length

  while i < len
    key = keys[i - 1]
    val = (if "string" is typeof m[i] then decodeURIComponent(m[i]) else m[i])
    if key
      params[key.name] = val
    else
      params.push val
    ++i
  true
