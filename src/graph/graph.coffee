Edge = require './edge'
Vertex = require './vertex'

module.exports = class Graph
  edgeClass: Edge
  vertexClass: Vertex

  constructor: ->
    @vertices = {}
    @edges = []

  hasVertex: (label) ->
    !!@vertices[label]

  vertex: (label) ->
    return label if label instanceof @vertexClass
    @vertices[label] or= new Vertex(@, label)

  removeVertex: (label) ->
    return unless @hasVertex(label)
    @vertex(label).destroy()

  hasEdge: (vertices...) ->
    !!@edges[@edgeClass.id(vertices...)]

  edge: (v1, v2, attributes = {}) ->
    result = @edges[@edgeClass.id(v1, v2)] or= new @edgeClass(@, v1, v2)
    result.attributes[k] = v for own k, v of attributes
    result

  removeEdge: (vertices...) ->
    return unless @hasEdge(vertices...)
    @edge(vertices...).destroy()

  size: ->
    Object.keys(@edges).length

  order: ->
    Object.keys(@vertices).length