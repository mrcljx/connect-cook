module.exports = class Vertex
  nextVertexId = do ->
    id = 0
    -> id++

  constructor: (@graph, @label) ->
    @id = nextVertexId()
    @edges = []

  destroy: ->
    return unless @destroyed
    @destroyed = true

    # remove from graph
    delete @graph[@label]

    # delete all edges
    @edges.forEach (edge) ->
      @edge.destroy()

  reachable: (predicate) ->
    result = []
    
    _walk = (v1) ->
      result.push(v1)

      v1.edges.forEach (edge) ->
        v2 = edge.vertices[1-edge.vertices.indexOf(v1)]
        return unless predicate(v1, edge, v2)
        return if result.indexOf(v2) >= 0
        _walk(v2)
    
    _walk(@)
    result.shift()
    result
  
  adj: ->
    @reachable (v1, e, v2) ->
      e.canWalk(v1)

  @comparer: (v1, v2) ->
    v1.id - v2.id