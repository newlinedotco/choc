{puts,inspect} = require("util")
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")

# TODOs 
# return a + b in a function ReturnStatement placement
# While statement placement - ending part

isStatement = (thing) ->
  statements = [
    'BreakStatement', 'ContinueStatement', 'DoWhileStatement',
    'DebuggerStatement', 'EmptyStatement', 'ExpressionStatement', 'ForStatement',
    'ForInStatement', 'IfStatement', 'LabeledStatement', 'ReturnStatement',
    'SwitchStatement', 'ThrowStatement', 'TryStatement', 'WhileStatement',
    'WithStatement',

    'VariableDeclaration'
  ]
  _.contains(statements, thing)

# Executes visitor on the object and its children (recursively).
traverse = (object, visitor, path) ->
  key = undefined
  child = undefined
  path = []  if typeof path is "undefined"
  visitor.call null, object, path
  for key of object
    if object.hasOwnProperty(key)
      child = object[key]
      traverse child, visitor, [object].concat(path) if typeof child is "object" and child isnt null

collectStatements = (code, tree) ->
  statements = []
  traverse tree, (node, path) ->
    if isStatement(node.type)
      statements.push { node: node, path: path }
  statements

tracers = 
  postStatement: (traceName) ->
    (code) ->
      tree = esprima.parse(code, { range: true, loc: true })
      statementList = collectStatements(code, tree)

      fragments = []
      i = 0
      while i < statementList.length
        node = statementList[i].node
        nodeType = node.type
        line = node.loc.start.line
        range = node.range
        pos = node.range[1]

        if node.hasOwnProperty("body")
          pos = node.body.range[0] + 1
        else if node.hasOwnProperty("block")
          pos = node.block.range[0] + 1

        if typeof traceName is "function"
          signature = traceName.call(null,
            line: line
            range: range
          )
        else
          signature = traceName + "({ "
          signature += "lineNumber: " + line + ", "
          signature += "range: [" + range[0] + ", " + range[1] + "], "
          signature += "type: '" + nodeType + "' "
          signature += "});"

        signature = " " + signature + ""
        fragments.push
          index: pos
          text: signature

        i += 1

      fragments

preamble = 
  trace: (opts) ->
    __choc_count = 0
    (info) =>
      __choc_count = __choc_count + 1
      console.log("count:  #{__choc_count}/#{opts.count} type: #{info.type}")
      if __choc_count >= opts.count
        throw new Error("__choc_pause")

scrub = (source, count) ->
  modifiers = [ tracers.postStatement("__choc_trace") ]
  morphed = esmorph.modify(source, modifiers)

  chocified = """
    __choc_trace = (#{preamble.trace.toString()})({count: #{count}})
    #{morphed}
  """
  
  chocified

# source = """
# // Life, Universe, and Everything
# var answer = 6 * 7;
# var foo = "bar";
# console.log(answer); console.log(foo);

# // parabolas
# var shift = 0;
# while (shift <= 200) {
#   // console.log(shift);
#   shift += 14; // increment
# }
# """
# new_source = scrub(source, 10)
# puts new_source
# eval new_source

exports.scrub = scrub

