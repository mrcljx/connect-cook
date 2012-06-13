coffee = try require.main.require 'coffee-script' catch e

unless coffee
  module.exports = false
  return

fs = require 'fs'

module.exports =
  contentType: "text/javascript"
  comment: '#='
  compile: (file, callback) ->


    fs.readFile file, 'utf8', (err, content) ->
      return callback(err) if err

      callback null, coffee.compile(content)
