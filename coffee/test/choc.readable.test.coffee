testHelper = require('./test_helper')
{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
assert = require('assert')
should = require("should")
readable = require("../src/readable")
coffee = require("coffee-script")

describe 'Readable', ->

  message = (code, opts={}) ->
    nodes = esprima.parse(code, {range: true, loc: true})#.body[0]
    pp nodes
    readable.readableNode(nodes.body[0], opts)


  messageE = (code, opts={}) ->
    beforeCode = opts.before || ""
    toEval = beforeCode + ";" + code + "; " + message(code, opts)
    eval(toEval)

  it 'simple assignment', () ->
    code = "var foo = 0"
    messageE(code)[0].message.should.eql 'Create the variable <span class="choc-variable">foo</span> and set it to <span class="choc-value">0</span>'

  it 'assignment and increment', () ->
    code = "foo = 1 + bar"
    pp message(code)

  it 'function calls with no annotations', () ->
    code = "console.log('hello')"
    pp message(code)

  it 'function calls with annotations', () ->
    before = """
    annotatedfn = () ->
    annotatedfn.__choc_annotation = (args) ->
      return "'i was annotated with ' + " + "'" + readable.generateReadableExpression(args[0]) + "'"
    """
    before = coffee.compile(before, bare: true)
    code = "annotatedfn('hello')"
    result = messageE(code, before: before)
    result[0].message.should.eql 'i was annotated with hello'

  it 'return statements', () ->
    code =  """
    function a() {
      return(1 + 2);
    }
    """
    pp message(code)

  it 'member functions', () ->
    code = """
      var bob = {}
      bob.add = function(a, b){
        return a + b;
      }

      var x = bob.add(1, 2) + bob.add(3, 4);
      var y = x;
    """

    pp message(code)

