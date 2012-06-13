fs = require 'fs'
path = require 'path'
async = require 'async'

DependencyManager = require './dependency_manager'
Asset = require './asset'
{ readDirRecursive, log, _ } = require './utils'

module.exports = class Cook
  defaultOptions =
    eager: false
    output: false
    src: [ path.join(process.cwd(), 'assets') ]
    dest: path.join(process.cwd(), 'public')
    mount: '/'

  constructor: (options = {}) ->
    log "INFO", "Initialzing..."

    @options = {}
    _.extend(@options, defaultOptions, options)

    @files = {}
    @assets = {}
    @compilers = {}
    @bundles = {}
    @cache = {}
    @deps = new DependencyManager(@invalidate.bind())

    ['coffee', 'less', 'styl', 'js', 'css'].forEach (ext) =>
      compiler = require "./compilers/#{ext}"
      @addCompiler ext, compiler if compiler

    @watch ->
      log "INFO", "Init done."

    @middleware = @middleware.bind(@)
    @middleware.cook = @

  bundleProvider: (req, res, next, bundle) ->

    asset = @assets["/#{bundle}"]

    return next() unless asset

    all = asset.bundle()

    filter = (exp) -> (item) -> exp.test(item.url)
    mapper = (item) -> "#{item.url}?#{item.mtime}"

    scripts = JSON.stringify all.filter(filter(/\.js$/)).map(mapper)
    styles  = JSON.stringify all.filter(filter(/\.css$/)).map(mapper)

    response = """
      (function() {
        var head = document.getElementsByTagName("head")[0];

        function loadScript(src) {
          var el = document.createElement('script');
          el.setAttribute("src", src)
          el.setAttribute("type", "text/javascript");
          el.async = false;

          head.appendChild(el);
        }

        function loadStyle(src) {
          var el = document.createElement('link');
          el.setAttribute("href", src)
          el.setAttribute("rel", "stylesheet");
          head.appendChild(el);
        }

        #{scripts}.forEach(function(script) {
          loadScript(script);
        });

        #{styles}.forEach(function(script) {
          loadStyle(script);
        });
      }());
    """

    res.setHeader "Content-Type", "text/javascript"
    res.send response

  middleware: (req, res, next) ->
    url = req.url
    queryStart = url.indexOf('?')
    url = url.slice(0, queryStart) if queryStart >= 0

    match = /^\/cook-bundle\/([a-zA-Z0-9\._-]+)$/.exec(url)

    if match
      @bundleProvider req, res, next, match[1]
      return

    asset = @assets[url]
    return next() unless asset

    log "ASSET", "Requested %s.", url

    serve = (cached) ->
      res.setHeader 'Content-Type', cached.type
      res.setHeader 'Content-Length', cached.length
      res.end cached.data

    # Do we have that file in our cache?
    if url of @cache
      log "ASSET", "Serving cached data for %s", url
      serve @cache[url]
    else
      asset.compile (err, result) =>
        return next(err) if err

        result or= ""

        @cache[url] =
          type: asset.contentType
          length: result.length
          data: result

        serve @cache[url]

  invalidate: (assetUrl, callback) =>
    log "INVALIDATE", assetUrl

    delete @cache[assetUrl]

    asset = @assets[assetUrl]
    asset.touch()

    if @options.eager
      asset.preprocess callback
    else
      callback()

  registerFile: (file, callback) ->
    log "FILE", "%s", file

    throw new Error("Registered #{file} multiple times.") if file of @files

    extension = path.extname(file)
    return unless extension of @compilers
    asset = new Asset(@, file)
    @files[file] = asset
    @assets[asset.url] = asset

    @deps.invalidate(asset.url)

    callback?()

  watch: (callback) ->
    log "INFO", "Searching for files."

    iterator = (item, callback) =>
      readDirRecursive(item, @registerFile.bind(@), callback)

    async.forEach @options.src, iterator, callback

  addCompiler: (ext, compiler) ->
    log "INFO", "Compiler for .#{ext} registered."
    @compilers[".#{ext}"] = compiler

  registerHelpersAt: (locals) ->

    locals.js = locals.css = (bundle) ->
      "<script type='text/javascript' src='/cook-bundle/#{bundle}'></script>"

    return

    locals.asset = (assetName, wrapper) =>
      wrapper or= (i) -> i

      asset = @assets[assetName]
      throw new Error("No such asset: " + assetName) unless asset
      asset.bundle().map(wrapper).join("")

    locals.css = (assetName) =>
      locals.asset assetName, (item) ->
        "<link href='#{item.url}?#{item.mtime}' rel='stylesheet' />"

    locals.js = (assetName) =>
      locals.asset assetName, (item) ->
        "<script type='text/javascript' src='#{item.url}?#{item.mtime}' /></script>"
