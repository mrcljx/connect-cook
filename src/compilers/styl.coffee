fs = require 'fs'
path = require 'path'

stylus = try require.main.require 'stylus' catch e

unless stylus
  module.exports = false
  return

nib = try require.main.require 'nib' catch e then (-> ->)
bootstrap = try require.main.require 'bootstrap-stylus' catch e then (-> ->)

module.exports =
  contentType: "text/css"
  compile: (file, callback) ->
    configurator = (renderer) ->
      renderer.options.paths.push(path.dirname(file))

    fs.readFile file, "utf8", (err, source) ->
      compiler = stylus(source)
        .set('filename', file)
        .use(configurator)
        .use(nib())
        .use(bootstrap())

      compiler.render callback