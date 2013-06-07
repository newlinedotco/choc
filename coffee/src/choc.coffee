# Choc: An Experiment in Learnable Programming
#
# References: 
# 
#
{puts,inspect} = require("util")
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")

# TODOs 
# return a + b in a function ReturnStatement placement
# While statement placement - ending part

Choc = 
  VERSION: "0.0.1"
  TRACE_FUNCTION_NAME: "__choc_trace"
  PAUSE_ERROR_NAME: "__choc_pause"
  EXECUTION_FINISHED_ERROR_NAME: "__choc_finished"

isStatement = (thing) ->
  statements = [
    'BreakStatement', 'ContinueStatement', 'DoWhileStatement',
    'DebuggerStatement', 'EmptyStatement', 'ExpressionStatement',
    'ForStatement', 'ForInStatement', 'IfStatement', 'LabeledStatement',
    'ReturnStatement', 'SwitchStatement', 'ThrowStatement', 'TryStatement',
    'WhileStatement', 'WithStatement',

    'VariableDeclaration'
  ]
  _.contains(statements, thing)

# Executes visitor on the object and its children (recursively).- from esmorph
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
  # based on a tracer from esmorph
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

class Tracer
  constructor: (options={}) ->
    @step_count = 0

  trace: (opts) =>
    @step_count = 0
    (info) =>
      @step_count = @step_count + 1
      # console.log("count:  #{@step_count}/#{opts.count} type: #{info.type}")
      if @step_count >= opts.count
        error = new Error(Choc.PAUSE_ERROR_NAME)
        error.info = info
        throw error

generateScrubbedSource = (source, count) ->
  modifiers = [ tracers.postStatement(Choc.TRACE_FUNCTION_NAME) ]
  morphed = esmorph.modify(source, modifiers)
  morphed

noop = () -> 

scrub = (source, count, opts) ->
  notify      = opts.notify  || noop
  beforeEach  = opts.beforeEach  || noop
  afterEach   = opts.afterEach   || noop
  locals  = opts.locals  || []
  newSource = generateScrubbedSource(source, count)

  locals.Choc = Choc
  localsStr = _.map(_.keys(locals), (name) -> "var #{name} = locals.#{name};").join("; ")

  try
    beforeEach()

    tracer = new Tracer()
    __choc_trace = tracer.trace(count: count)
    # http://perfectionkills.com/global-eval-what-are-the-options/
    eval(localsStr + "\n" + newSource)

    # if you make it here, execution finished
    console.log(tracer.step_count)
  catch e
    if e.message == Choc.PAUSE_ERROR_NAME
      notify(e.info)
    # else if e.message == Choc.EXECUTION_FINISHED_ERROR_NAME
    #  throw e
    else
      throw e
  finally
    afterEach()

if require? && (require.main == module)
  source = """
  // Life, Universe, and Everything
  var answer = 6 * 7;
  var foo = "bar";
  console.log(answer); console.log(foo);

  // parabolas
  var shift = 0;
  while (shift <= 200) {
    // console.log(shift);
    shift += 14; // increment
  }
  """
  scrubNotify = (info) ->
    puts inspect info

  scrub(source, 10, notify: scrubNotify)

exports.scrub = scrub

todo = """
  * highlight current line
  * parse only once
"""
