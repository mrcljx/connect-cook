path = require 'path'
fs = require 'fs'
{ log, _ } = require './utils'

module.exports = class Asset
  constructor: (@cook, @file) ->
    @url = @buildUrl()
    @graph = @cook.deps.graph

    log "ASSET", "%s", @url

    @watch()

  buildUrl: ->
    source = _(@cook.options.src).detect (src) =>
      @file.indexOf(src) == 0

    url = path.join @cook.options.mount, @file.slice(source.length)
    urlParts = url.split('/')
    basename = urlParts.pop()
    baseParts = basename.split('.')

    while baseParts.length > 2
      popped = baseParts.pop()
      extName = baseParts[baseParts.length-1]

      unless @cook.compilers[".#{extName}"]
        baseParts.push popped
        break

    @basename = baseParts.join "."
    @assetName = baseParts.slice(0, baseParts.length-1).join "."

    @cook.options.mount + path.join(urlParts..., baseParts.join("."))

  watch: ->
    log "WATCH", "%s", @file

    fs.watchFile @file, { persistent: false }, (curr, prev) =>
      return unless +curr.mtime != +prev.mtime
      @touch()
      @invalidate()

  touch: ->
    @mtime = new Date().getTime()

  vertex: ->
    @graph.vertex(@url)

  bundle: ->
    result = []

    predicate = (v1, edge, v2) ->
      edge.canWalk(v1) and edge.attributes.imports

    @vertex().reachable(predicate).forEach (v) =>
      result.push @cook.assets[v.label]

    result.push @
    result

  isPartial: ->
    @basename.charAt(0) == "_"

  matches: (otherBasename) ->
    @basename == otherBasename or @assetName == otherBasename

  compiler: ->
    extension = path.extname(@file)
    @cook.compilers[extension]

  invalidate: ->
    @cook.deps.invalidate(@url)

  addImport: (other) ->
    log "IMPORT", "#{@url} imports #{other}"

    dependsOn = @graph.vertex(other)

    @graph.edge @vertex(), dependsOn,
      imports: true

  addDependency: (other) ->
    log "DEPENDENCY", "#{@url} depends on #{other}"

    dependsOn = @graph.vertex(other)

    @graph.edge dependsOn, @vertex(),
      depends: true

  preprocess: (callback) ->
    compiler = @compiler()
    commentIntro = compiler.comment

    @contentType = compiler.contentType
    @contentType or= "application/octet-stream"

    return callback?() unless commentIntro
    log "PREPROCESS", @url

    fs.readFile @file, "utf8", (err, data) =>
      return callback(err) if err

      lines = data.split "\n"

      line = lines.shift()

      while line and line.indexOf(commentIntro) == 0
        line = line.slice(commentIntro.length)
        line = line.replace("\r", "")

        match = /^\s*([\w_]+)\s+(["'])?([\w\._\/\\-]+)\2\s*$/.exec(line)

        unless match
          console.log "Failed to parse #{line}"
          continue

        directive = match[1]
        requirement = match[3]

        importedFile = path.join(path.dirname(@file), requirement)
        importedFile = path.normalize(importedFile)

        log "SPROCKET", "%s %s(%s) -> ", @url, directive, requirement, importedFile

        switch directive
          when "require_tree"
            unless importedFile.charAt(importedFile.length-1) == "/"
              importedFile += "/"

            for own f, asset of @cook.files
              if f.indexOf(importedFile) == 0
                @addImport(asset.url)
          when "require"
            for own f, asset of @cook.files
              continue if f.indexOf(importedFile) != 0
              continue if path.dirname(asset.file) != path.dirname(importedFile)
              continue unless asset.matches(path.basename(importedFile))
              @addImport asset.url

          else
            log "WARN", "Unknown directive: %s.", directive


        line = lines.shift()

      callback()

  compile: (callback) ->
    log "COMPILE", @file

    @preprocess =>
      return callback?("is partial") if @isPartial()

      compiler = @compiler()

      unless compiler.compile
        fs.readFile @file, "utf-8", callback
        return

      try
        compiler.compile @file, (err, result, dependencies) =>
          return callback(err) if err

          dependencies or= []
          dependencies.forEach (d) => @addDependency(d)

          callback null, result

      catch e
        callback e

  destroy: ->
    @vertex.destroy()
