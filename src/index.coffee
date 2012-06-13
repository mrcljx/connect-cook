Cook = require './cook'

module.exports = (options) ->
  cook = new Cook(options)
  cook.middleware

module.exports.Cook = Cook