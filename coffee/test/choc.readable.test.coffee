testHelper = require('./test_helper')
{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
assert = require('assert')
should = require("should")
readable = require("../src/readable")

describe 'Readable', ->

  message = (code) ->
    nodes = esprima.parse(code, {range: true, loc: true}).body[0]
    pp nodes
    readable.readableNode(nodes)

  messageE = (code) ->
    eval(code + "; " + message(code))

  it 'simple assignment', () ->
    code = "var foo = 0"
    messageE(code)[0].message.should.eql 'Create the variable <span class="choc-variable">foo</span> and set it to <span class="choc-value">0</span>'

  it 'assignment and increment', () ->
    code = "foo = 1 + bar"
    pp message(code)

  it.only 'function calls', () ->
    code = "console.log('hello')"
    pp message(code)


