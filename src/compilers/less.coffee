fs = require 'fs'
path = require 'path'
util = require 'util'

less = try require.main.require 'less' catch e

unless less
  module.exports = false
  return

module.exports =
  contentType: "text/css"
  comment: "//="
  compile: (file, callback) ->
    fs.readFile file, "utf-8", (err, content) ->
      return callback(err) if err

      parser = new less.Parser
        filename: file
        paths: [path.dirname(file)]

      parser.parse content, (err, tree) ->
        return callback(err) if err

        dependencies = []
        for own importedFile, info of parser.imports.files
          dependencies.push path.join(path.dirname(file), importedFile)

        try
          css = tree.toCSS()

        catch err
          format = "Error in '%s' at (%d,%d): %s\n\n%s"

          errorMessage = util.format format,
            err.filename,
            err.line, err.column,
            err.message,
            err.extract?.join?("\n")

          errorMessage = errorMessage.replace(/\n/g, "\\A ")

          css = "body:before {
            white-space: pre;
            font-family: monospace;
            content: \"#{errorMessage}\";
          }

          body > * {
            display: none;
          }"

        callback null, css, dependencies
