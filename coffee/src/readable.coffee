{puts,inspect} = require("util")
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")


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


exports.readableNode = readableNode
