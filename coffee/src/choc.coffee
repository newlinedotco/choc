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
readable = require("./readable")
debug = require("debug")("choc")

# TODOs 
# * return a + b in a function ReturnStatement placement
# * if statements - hoist conditional into tmp and put a trace before calling the if
# * While statement placement - ending part
# * add a trace at the very last step that says 'done'
# * parse only once
# * function returns - i think we're going to need to transform every ReturnStatement to hoist its argument into a variable - then give the language for that variable and pause on that line right before you return it
# * function calls on the line - 

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

      # puts inspect tree, null, 10

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
          puts inspect node, null, 10
          messagesString = readable.readableNode(node)

          signature = traceName + "({ "
          signature += "lineNumber: " + line + ", "
          signature += "range: [" + range[0] + ", " + range[1] + "], "
          signature += "type: '" + nodeType + "', "
          signature += "messages: " + messagesString + " "
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
    @onMessages = () ->
    @clearTimeline()

  clearTimeline: () ->
    @timeline = {
      steps: []
      stepMap: {}
      maxLines: 0
    }

  trace: (opts) =>
    @step_count = 0
    (info) =>
      @timeline.steps[@step_count] = {lineNumber: info.lineNumber}
      @timeline.stepMap[@step_count] ||= {}
      @timeline.stepMap[@step_count][info.lineNumber - 1] = true
      @timeline.maxLines = Math.max(@timeline.maxLines, info.lineNumber)
      info.frameNumber = @step_count # todo revise this language

      @step_count = @step_count + 1
      # console.log("count:  #{@step_count}/#{opts.count} type: #{info.type}")
      if @step_count >= opts.count
        @onMessages(info.messages)
        error = new Error(Choc.PAUSE_ERROR_NAME)
        error.info = info
        throw error

generateScrubbedSource = (source, count) ->
  modifiers = [ tracers.postStatement(Choc.TRACE_FUNCTION_NAME) ]
  morphed = esmorph.modify(source, modifiers)
  morphed

noop = () -> 

scrub = (source, count, opts) ->
  onFrame     = opts.onFrame      || noop
  beforeEach  = opts.beforeEach  || noop
  afterEach   = opts.afterEach   || noop
  afterAll    = opts.afterAll    || noop
  onTimeline  = opts.onTimeline  || noop
  onMessages  = opts.onMessages  || noop
  locals      = opts.locals  || []
  newSource   = generateScrubbedSource(source, count)

  debug(newSource)
  executionTerminated = false

  try
    beforeEach()

    tracer = new Tracer()
    tracer.onMessages = onMessages
    tracer.onTimeline = onTimeline

    # create a few functions to be used by the eval'd source
    __choc_trace         = tracer.trace(count: count)
    __choc_first_message = (messages) -> messages[0]?.message || "TODO"

    # add our own local vars
    locals.Choc = Choc

    # define any user-given locals as a string for eval'ing
    localsStr = _.map(_.keys(locals), (name) -> "var #{name} = locals.#{name};").join("; ")

    # http://perfectionkills.com/global-eval-what-are-the-options/
    eval(localsStr + "\n" + newSource)

    # if you make it here without an exception, execution finished
    executionTerminated = true
  catch e
    # throwing a Choc.PAUSE_ERROR_NAME is how we pause execution (for now)
    # the most obvious consequence of this is that you can't have a catch-all
    # exception handler in the code you wish to trace
    if e.message == Choc.PAUSE_ERROR_NAME
      onFrame(e.info)
    else
      throw e
  finally
    afterEach()

    if executionTerminated
      afterAll({step_count: tracer.step_count})
      onTimeline(tracer.timeline)

exports.scrub = scrub
