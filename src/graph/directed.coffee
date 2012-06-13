Edge = require './edge'
Graph = require './graph'

class DirectedEdge extends Edge
  constructor: (@graph, @vertices...) ->
    @id = DirectedEdge.id(@vertices...)
    @attributes = {}
    @vertices.forEach (v) => v.edges.push(@)

  canWalk: (from) ->
    @vertices[0] == from

  @id: (vertices...) ->
    vertices.map((v) -> v.id).join("::")

class DirectedGraph extends Graph
  edgeClass: DirectedEdge

module.exports = { DirectedEdge, DirectedGraph }