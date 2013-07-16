testHelper = require('./test_helper')
{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
assert = require('assert')
readable = require("../src/readable")

describe 'Readable', ->

  message = (code) ->
    nodes = esprima.parse(code, {range: true, loc: true}).body[0]
    readable.readableNode(nodes)

  messageE = (code) ->
    eval(code + "; " + message(code))

  it 'does something useful', () ->
    code = "var foo = 0"
    msg = messageE(code)[0].message
    puts msg
    assert.ok true

