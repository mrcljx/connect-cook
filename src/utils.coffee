fs = require 'fs'
path = require 'path'
_ = require 'underscore'
_.mixin require 'underscore.string'

exports._ = _

LOG = (process.env.LOG?.indexOf?("cook") >= 0)

exports.forEachAsync = (array, action, onComplete) ->
  i = 0

  next = ->
    if i >= array.length
      onComplete?()
    else
      item = array[i++]
      action(next, item, i-1, array)

  next()

exports.log = (type, message, args...) ->
  return unless LOG
  typePart = _("[COOK - #{type}]").rpad(20)
  console.log "#{typePart} #{message}", args...

exports.readDirRecursive = (dir, onFile, onComplete) ->
  _walk = (dir, onComplete) ->
    fs.readdir dir, (err, entries) ->
      return onComplete(err) if err

      onEntry = (next, entry) ->
        fullPath = path.join(dir, entry)
        fs.stat fullPath, (err, stat) ->
          if err
            next()
          else if stat.isFile()
            onFile(fullPath)
            next()
          else if stat.isDirectory()
            _walk(fullPath, next)
          else
            next()

      exports.forEachAsync entries, onEntry, onComplete

  _walk(dir, onComplete)