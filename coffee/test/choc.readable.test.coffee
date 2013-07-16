testHelper = require('./test_helper')
{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
assert = require('assert')
readable = require("../src/readable")
coffeeson = require("coffee-son")

describe 'Readable', ->
  it 'does', () ->
    code = "__choc_trace({ lineNumber: 4, range: [ 4, 4 ], type: 'nodeType', messages: 'messagesString' });"
    node = esprima.parse(code).body[0]
    # pp node
    # puts coffeeson.render(node)

  it 'does something useful', () ->
    code = "var foo = 0"
    node = esprima.parse(code, {range: true, loc: true}).body[0]
    # pp readable.readableNode(node)
    assert.ok true

  it.only 'two', () ->
    messages = """
       [ 
         {"lineNumber": 1, "message": "hello " + who}
       ]

    """
    messages = """
    var _fn = function () {
          return true;
        } 
    """
    node = esprima.parse(messages, {tolerant: true}).body[0].declarations[0].init

    # messages = """
    #   foo({"foo": console.log(1)})
    # """
    # node = esprima.parse(messages, {tolerant: true}).body[0]
    
    puts messages
    pp node
