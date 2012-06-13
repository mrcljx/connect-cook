connect = require('connect')
Cook = require './src/cook'

cook = new Cook
  eager: true

setInterval((() -> ), 1)
return

app = connect()

app.use(new Cook().middleware)

app.use (req, res) ->
  body = 'Hello World'
  res.setHeader 'Content-Length', body.length
  res.end body

app.listen(8081)