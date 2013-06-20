{puts,inspect} = require("util")
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")


generateReadableExpression = (node, opts={}) ->
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
        "<=": "__choc_first_message(#{generateReadableExpression(node.left)}) + ' <= ' + __choc_first_message(#{generateReadableExpression(node.right)})" 
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
      "[ { lineNumber: #{node.loc.start.line}, message: #{message} } ]"
    when 'Literal'
      "[ { lineNumber: #{node.loc.start.line}, message: '#{node.value}' } ]"
    when 'Identifier'
      "[ { lineNumber: #{node.loc.start.line}, message: #{node.name} } ]"
    else
      "[]"

generateReadableStatement = (node, opts={}) ->
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
    when 'WhileStatement'
      # ugh - I do not like this API - TODO
      puts inspect node
      conditional = if opts.hoistedAttributes
          opts.hoistedAttributes[1] # TODO
        else 
          true # should this ever happen? no 
      """
      (function (__conditional) { 
       if(__conditional) { 
         var startLine = #{node.loc.start.line};
         var endLine   = #{node.loc.end.line};
         var messages = [ { lineNumber: startLine, message: "Because " + __choc_first_message(#{generateReadableExpression(node.test)}) } ]
         for(var i=startLine+1; i<= endLine; i++) {
           var message = i == startLine+1 ? "do this" : "and this";
           messages.push({ lineNumber: i, message: message });
         }
         messages.push( { lineNumber: endLine, message: "... and try again" } )
         // do this
         // and this
         // ... and try again
         return messages;
       } else {
         // Because -> condition with variables expanded e.g. 0 <= 200 is false
         // ... stop looping
         var startLine = #{node.loc.start.line};
         var endLine   = #{node.loc.end.line};
         var messages = [ { lineNumber: startLine, message: "Because " + __choc_first_message(#{generateReadableExpression(node.test)}) + " is false"} ]
         messages.push( { lineNumber: endLine, message: "stop looping" } )
         return messages;
       }
      })(#{conditional})
    """ 
    else
      "[]"
  
readableNode = (node, opts={}) ->
  switch node.type
    when 'VariableDeclaration', 'ExpressionStatement', 'WhileStatement'
      generateReadableStatement(node, opts)
    when 'AssignmentExpression'
      generateReadableExpression(node, opts)
    else
      "[]"


exports.readableNode = readableNode
