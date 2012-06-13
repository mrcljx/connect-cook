module.exports = class Edge
  constructor: (@graph, vertices...) ->
    @id = Edge.id(vertices...)
    @attributes = {}
    @vertices = vertices.sort(@graph.vertexClass.comparer)
    @vertices.forEach (v) => v.edges.push(@)

  destroy: ->
    return unless @destroyed
    @destroyed = true

    # remove from graph
    delete @graph[@id]

    # remove from nodes
    @vertices.forEach (v) =>
      index = v.indexOf(@)
      v.edges.splice(1) if index >= 0

  canWalk: (from) ->
    @vertices.indexOf(from) >= 0
  
  @id: (vertices...) ->
    vertices.sort(@graph.vertexClass.comparer).map((v) -> v.id).join("::")
