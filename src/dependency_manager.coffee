{ log, forEachAsync, _ } = require './utils'
{ EventEmitter } = require 'events'

path = require 'path'

{ DirectedGraph } = require './graph/directed'
Asset = require './asset'

module.exports = class DependencyManager extends EventEmitter
  constructor: (@callback) ->
    @graph = new DirectedGraph()
    @invalidated = {}
    @_compileInvalid = _.debounce(@_compileInvalid, 100)
    @compiling = false

  _compileInvalid: ->
    invalidated = @invalidated
    @invalidated = {}
    @compiling = true

    invalidated = Object.keys(invalidated)
    log "INFO", "Recompiling #{invalidated.length} files..."

    recompile = (next, file) =>
      @callback file, next

    forEachAsync invalidated, recompile, =>
      log "INFO", "All compilation done."
      @compiling = false
      @_compileInvalid() if @invalidated.length > 0

  # flags an asset and all assets that depend on it
  # as invalid
  invalidate: (assetUrl) ->
    return if assetUrl of @invalidated

    ifDepends = (v1, edge, v2) ->
      edge.canWalk(v1) and edge.attributes.depends

    vertex = @graph.vertex(assetUrl)

    vertex.reachable(ifDepends).concat(vertex).forEach (v) =>
      log "INVALID", v.label
      @invalidated[v.label] = true
      v.destroy()

    @_compileInvalid()
