testHelper = require('./test_helper')
{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
assert = require('assert')
readable = require("../src/readable")

describe 'Readable', ->
  it 'does something useful', () ->
    code = "var foo = 0"
    nodes = esprima.parse(code).body[0]
    assert.ok true

 
