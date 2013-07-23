{puts,inspect} = require("util"); pp = (x) -> puts inspect(x, null, 1000)
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")

# Javascript isn't homoiconic. So we have two options: 1. Rewrite this in a
# homoiconic language or 2. use eval. The code below is atrocious. Until
# javascript has macros, this will have to do. I hope you'll be delighted in
# the interface enough to overlook the warts in the implementation.
generateReadableValue = (node1, node2, opts={}) ->
  if node1.name
    "#{node1.name}"
  else
    switch node2.type
      when 'FunctionExpression'
        "'this function'"
      else
        "'TODO'"

# generateTimeline separately

generateReadableExpression = (node, opts={}) ->
  switch node.type
    when 'AssignmentExpression'
      operators = 
        "=":  "'set ' + #{generateReadableExpression(node.left, {want: "name"})} + ' to ' + #{generateReadableValue(node.left, node.right)}, timeline: #{generateReadableValue(node.left, node.right)}"
        "+=": "'add ' + #{generateReadableExpression(node.right)} + ' to #{node.left.name} and set #{node.left.name} to ' + #{node.left.name}, timeline: #{node.left.name}"
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
      target = node.callee?.name || (node.callee.object.name + "." + node.callee.property.name)
      """
      (function() {
        if(#{target}.hasOwnProperty("__choc_annotation")) {
          return eval(#{target}.__choc_annotation(#{inspect(node.arguments, null, 1000)}));
        } else if (#{if node.callee?.name? then "true" else "false"}) {
          return "call the function <span class='choc-variable'>#{node.callee.name}</span>";
        } else if (#{if node.callee?.object?.name then "true" else "false"}) {
          return "tell <span class='choc-variable'>#{node.callee?.object?.name}</span> to <span class='choc-variable'>#{node.callee?.property?.name}</span>";
        } else {
          return "";
        }
      })()
      """
    when "MemberExpression"
      "'#{node.object.name}\\\'s #{node.property.name}'"
    when 'Literal'
      "#{node.value}"
    when 'Identifier'
      if opts.want == "name"
        "'#{node.name}'"
      else
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
    when 'CallExpression'
      "[ { lineNumber: #{node.loc.start.line}, message: " + generateReadableExpression(node) + " } ]"
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
    when 'ReturnStatement'
      hoistedVar = if opts.hoistedAttributes
          opts.hoistedAttributes[1] # TODO
        else 
          "''" 
      "[ { lineNumber: #{node.loc.start.line}, message: 'return ' + " + hoistedVar + " } ]"
    else
      "[]"
  
readableNode = (node, opts={}) ->
  switch node.type
    when 'VariableDeclaration', 'ExpressionStatement', 'WhileStatement', 'IfStatement', 'ReturnStatement', 'CallExpression'
      generateReadableStatement(node, opts)
    else
      "[]"


exports.readableNode = readableNode
exports.generateReadableExpression = generateReadableExpression
