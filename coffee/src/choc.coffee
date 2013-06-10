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

generateReadableExpression = (node) ->
  switch node.type
    when 'AssignmentExpression'
      operators = 
        "=":  "'set #{node.left.name} to ' + __choc_first_message(#{generateReadableExpression(node.right)})"
        "+=": "'add ' + __choc_first_message(#{generateReadableExpression(node.right)}) + ' to #{node.left.name} and set #{node.left.name} to ' + #{node.left.name}"
        "-=": "'subtract ' + __choc_first_message(#{generateReadableExpression(node.right)}) + ' from #{node.left.name}'"
        "*=": "'multiply #{node.left.name} by ' + __choc_first_message(#{generateReadableExpression(node.right)}) "
        "/=": "'divide #{node.left.name} by ' + __choc_first_message(#{generateReadableExpression(node.right)}) "
        "%=": "'divide #{node.left.name} by ' + __choc_first_message(#{generateReadableExpression(node.right)}) + ' and set #{node.left.name} to the remainder'"

      message = operators[node.operator] || ""
      "[ { lineNumber: #{node.loc.start.line}, message: #{message} }]"

    when 'BinaryExpression'
      operators = 
        "==": "''" 
        "!=" : "''"
        "===": "''" 
        "!==": "''"
        "<": "''"
        "<=": "''" 
        ">": "''"
        ">=": "''"
        "<<": "''"
        ">>": "''"
        ">>>": "''"
        "+": "'add ' + __choc_first_message(#{generateReadableExpression(node.right)}) + ' to #{node.left.name} and set #{node.left.name} to ' + #{node.left.name}"
        "-": "''"
        "*": "''"
        "/": "''" 
        "%": "''"
        "|": "''" 
        "^": "''"
        "in": "''"
        "instanceof": "''"
        "..": "''"

      message = operators[node.operator] || ""
      "[ { lineNumber: #{node.loc.start.line}, message: #{message} }]"
    when 'Literal'
      "[ { lineNumber: #{node.loc.start.line}, message: '#{node.value}' }]"
    else
      "[]"

generateReadableStatement = (node) ->
  switch node.type
    when 'VariableDeclaration'
      i = 0
      sentences = _.map node.declarations, (dec) -> 
        name = dec.id.name
        prefix = if i == 0 then "Create" else " and create"
        i = i + 1
        "'#{prefix} the variable <span class=\"choc-variable\">#{name}</span> and set it to <span class=\"choc-value\">' + #{name} + '</span>'"
      msgs = _.map sentences, (sentence) ->
         s  = "{ " 
         s += "lineNumber: " + node.loc.start.line + ", "
         s += "message: " + sentence 
         s += " }"
      "[ " + msgs.join(", ") + " ]"
    when 'ExpressionStatement'
      generateReadableExpression(node.expression)
    else
      "[]"
  
readableNode = (node) ->
  switch node.type
    when 'VariableDeclaration', 'ExpressionStatement'
      generateReadableStatement(node)
    when 'AssignmentExpression'
      generateReadableExpression
    else
      "[]"

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
          messagesString = readableNode(node)

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
      maxLines: 0
    }

  trace: (opts) =>
    @step_count = 0
    (info) =>
      @timeline.steps[@step_count] = {lineNumber: info.lineNumber}
      @timeline.maxLines = Math.max(@timeline.maxLines, info.lineNumber)

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
  notify      = opts.notify      || noop
  beforeEach  = opts.beforeEach  || noop
  afterEach   = opts.afterEach   || noop
  afterAll    = opts.afterAll    || noop
  onTimeline  = opts.onTimeline  || noop
  onMessages  = opts.onMessages  || noop
  locals  = opts.locals  || []
  newSource = generateScrubbedSource(source, count)

  puts newSource

  locals.Choc = Choc
  localsStr = _.map(_.keys(locals), (name) -> "var #{name} = locals.#{name};").join("; ")

  try
    beforeEach()

    tracer = new Tracer()
    tracer.onMessages = onMessages
    tracer.onTimeline = onTimeline
    __choc_trace = tracer.trace(count: count)
    __choc_first_message = (messages) -> messages[0]?.message || "TODO"
    # http://perfectionkills.com/global-eval-what-are-the-options/
    eval(localsStr + "\n" + newSource)

    # if you make it here, execution finished
    console.log(tracer.step_count)
    afterAll({step_count: tracer.step_count})
    onTimeline(tracer.timeline)
  catch e
    if e.message == Choc.PAUSE_ERROR_NAME
      notify(e.info)
    else
      throw e
  finally
    afterEach()

if require? && (require.main == module)

  source_todo = """
  function add(a, b) {
    var c = 3;
    return a + b;
  }

  var sub = function(a, b) {
    var c = 3;
    return a - b;
  }
  while (shift <= 200) {
    // console.log(shift);
    var x = add(1, shift);
    shift += 14; // increment
  }
  """

  source = """
  // Life, Universe, and Everything
  var answer = 6 * 7, question = 3;
  var foo = "bar";
  console.log(answer); console.log(foo);

  // parabolas
  var shift = 0;
  while (shift <= 200) {
    // console.log(shift);
    var foo = shift;
    foo = shift - 1;
    shift += 14; // increment
  }
  """
  scrubNotify = (info) ->
    puts inspect info

  scrub(source, 10, notify: scrubNotify)

exports.scrub = scrub

todo = """
  * parse only once
  * function returns - i think we're going to need to transform every ReturnStatement to hoist its argument into a variable - then give the language for that variable and pause on that line right before you return it
  * function calls on the line - 
"""
