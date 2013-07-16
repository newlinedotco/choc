{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")

# The code below is atrocious. I hope you'll find use in the interface and
# excuse the implementation.  Until javascript has macros, this will have to do.

generateReadableExpression = (node, opts={}) ->
  switch node.type
    when 'AssignmentExpression'
      operators = 
        "=":  "'set #{node.left.name} to ' + #{node.left.name}"
        "+=": "'add ' + #{generateReadableExpression(node.right)} + ' to #{node.left.name} and set #{node.left.name} to ' + #{node.left.name}"
        "-=": "'subtract ' + #{generateReadableExpression(node.right)} + ' from #{node.left.name}' + ' and set #{node.left.name} to ' + #{node.left.name}"
        "*=": "'multiply #{node.left.name} by ' + #{generateReadableExpression(node.right)} + ' and set #{node.left.name} to ' + #{node.left.name}"
        "/=": "'divide #{node.left.name} by ' + #{generateReadableExpression(node.right)} + ' and set #{node.left.name} to ' + #{node.left.name}"
        "%=": "'divide #{node.left.name} by ' + #{generateReadableExpression(node.right)} + ' and set #{node.left.name} to the remainder, ' + #{node.left.name}"

      message = operators[node.operator] || ""

    when 'BinaryExpression'
      operators = 
        "==": "#{generateReadableExpression(node.left)} + ' equals ' + #{generateReadableExpression(node.right)}" 
        "!=" : "#{generateReadableExpression(node.left)} + ' does not equal ' + #{generateReadableExpression(node.right)}" 
        "===": "#{generateReadableExpression(node.left)} + ' equals ' + #{generateReadableExpression(node.right)}" 
        "!==": "#{generateReadableExpression(node.left)} + ' does not equal ' + #{generateReadableExpression(node.right)}" 
        "<": "#{generateReadableExpression(node.left)} + ' less than ' + #{generateReadableExpression(node.right)}" 
        "<=": "#{generateReadableExpression(node.left)} + ' less than or equal to ' + #{generateReadableExpression(node.right)}" 
        ">": "#{generateReadableExpression(node.left)} + ' greater than ' + #{generateReadableExpression(node.right)}" 
        ">=": "#{generateReadableExpression(node.left)} + ' greater than or equal to ' + #{generateReadableExpression(node.right)}" 
        "<<": "#{node.left.name}"
        ">>": "#{node.left.name}"
        ">>>": "#{node.left.name}"
        "+": "#{node.left.name}"
        "-": "#{node.left.name}"
        "*": "#{node.left.name}"
        "/": "#{node.left.name}"
        "%": "#{generateReadableExpression(node.left)} + ' % ' + #{generateReadableExpression(node.right)}" # TODO pretend someone doesn't know what % means and write that
        "|": "#{node.left.name}" 
        "^": "#{node.left.name}"
        "in": "''"
        "instanceof": "''"
        "..": "''"

      message = operators[node.operator] || ""
      "#{message}"
    when 'CallExpression'
      console.log(node)
      # tell target to verb with parameters
      # but we want to allow some context specific language here
      # if we annotate the functions themselves, then we might be able to annotate prototypes, but maybe not local functions
      # if we pass a dictionary, then there is variable name ambiguity
      # node.callee.name || node.property.name
      target = node.callee?.name || (node.callee.object.name + "." + node.callee.property.name)
      """
      (function() {
        if(#{target}.hasOwnProperty("__choc_annotation")) {
          return #{target}.__choc_annotation(#{inspect(node.arguments, null, 1000)});
        } else {
          return "";
        }
      })()
      """
    when 'Literal'
      "'#{node.value}'"
    when 'Identifier'
      "#{node.name}"
    else
      ""

generateReadableStatement = (node, opts={}) ->
  switch node.type
    when 'VariableDeclaration'
      i = 0
      sentences = _.map node.declarations, (dec) -> 
        name = dec.id.name
        prefix = if i == 0 then "Create" else " and create"
        i = i + 1
        "'#{prefix} the variable <span class=\"choc-variable\">#{name}</span> and set it to <span class=\"choc-value\">' + #{name} + '</span>'"
      msgs = _.map sentences, (sentence) -> "{ lineNumber: #{node.loc.start.line}, message: #{sentence} }"

      "[ " + msgs.join(", ") + " ]"
    when 'ExpressionStatement'
      "[ { lineNumber: #{node.loc.start.line}, message: " + generateReadableExpression(node.expression) + " } ]"
    when 'WhileStatement'
      conditional = if opts.hoistedAttributes
          opts.hoistedAttributes[1] # TODO
        else 
          true
      """
      (function (__conditional) { 
       if(__conditional) { 
         var startLine = #{node.loc.start.line};
         var endLine   = #{node.loc.end.line};
         var messages = [ { lineNumber: startLine, message: "Because " + #{generateReadableExpression(node.test)} } ]
         // CodeMirror is ridiculously slow when removing these messages. TODO speed it up and add them back
         // for(var i=startLine+1; i<= endLine; i++) {
         //   var message = i == startLine+1 ? "do this" : "and this";
         //   messages.push({ lineNumber: i, message: message });
         // }
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
         var messages = [ { lineNumber: startLine, message: "Because " + #{generateReadableExpression(node.test)} + " is false"} ]
         messages.push( { lineNumber: endLine, message: "stop looping" } )
         return messages;
       }
      })(#{conditional})
    """ 
    when 'IfStatement'
      conditional = if opts.hoistedAttributes
          opts.hoistedAttributes[1] # TODO
        else 
          true
      """
      (function (__conditional) { 
       var startLine = #{node.loc.start.line};
       var endLine   = #{node.loc.end.line};
       if(__conditional) { 
         var messages = [ { lineNumber: startLine, message: "Because " + #{generateReadableExpression(node.test)} } ]
         return messages;
       } else {
         var messages = [ { lineNumber: startLine, message: "Because " + #{generateReadableExpression(node.test)} + " is false"} ]
         return messages;
       }
      })(#{conditional})
    """ 
    else
      "[]"
  
readableNode = (node, opts={}) ->
  switch node.type
    when 'VariableDeclaration', 'ExpressionStatement', 'WhileStatement', 'IfStatement'
      generateReadableStatement(node, opts)
    else
      "[]"


exports.readableNode = readableNode
exports.generateReadableExpression = generateReadableExpression
