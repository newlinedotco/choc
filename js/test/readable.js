var _ns_ = {
  "id": "choc.test.readable"
};
var ast = require("wisp/ast");
var symbol = ast.symbol;
var keyword = ast.keyword;
var isSymbol = ast.isSymbol;
var isKeyword = ast.isKeyword;;
var wisp_sequence = require("wisp/sequence");
var cons = wisp_sequence.cons;
var conj = wisp_sequence.conj;
var list = wisp_sequence.list;
var isList = wisp_sequence.isList;
var seq = wisp_sequence.seq;
var vec = wisp_sequence.vec;
var isEmpty = wisp_sequence.isEmpty;
var isSequential = wisp_sequence.isSequential;
var count = wisp_sequence.count;
var first = wisp_sequence.first;
var second = wisp_sequence.second;
var third = wisp_sequence.third;
var rest = wisp_sequence.rest;
var last = wisp_sequence.last;
var butlast = wisp_sequence.butlast;
var take = wisp_sequence.take;
var drop = wisp_sequence.drop;
var repeat = wisp_sequence.repeat;
var concat = wisp_sequence.concat;
var reverse = wisp_sequence.reverse;
var sort = wisp_sequence.sort;
var map = wisp_sequence.map;
var filter = wisp_sequence.filter;
var reduce = wisp_sequence.reduce;
var assoc = wisp_sequence.assoc;;
var wisp_runtime = require("wisp/runtime");
var str = wisp_runtime.str;
var isEqual = wisp_runtime.isEqual;
var dictionary = wisp_runtime.dictionary;;
var wisp_compiler = require("wisp/compiler");
var isSelfEvaluating = wisp_compiler.isSelfEvaluating;
var compile = wisp_compiler.compile;
var macroexpand = wisp_compiler.macroexpand;
var macroexpand1 = wisp_compiler.macroexpand1;
var compileProgram = wisp_compiler.compileProgram;;
var wisp_reader = require("wisp/reader");
var readFromString = wisp_reader.readFromString;;
var esprima = require("esprima");;
var underscore = require("underscore");
var has = underscore.has;;
var util = require("util");
var puts = util.puts;
var inspect = util.inspect;;
var choc_src_readableUtil = require("./../src/readable-util");
var toSet = choc_src_readableUtil.toSet;
var isSetIncl = choc_src_readableUtil.isSetIncl;
var partition = choc_src_readableUtil.partition;
var transpile = choc_src_readableUtil.transpile;
var pp = choc_src_readableUtil.pp;
var parseJs = choc_src_readableUtil.parseJs;
var when = choc_src_readableUtil.when;
var appendifyForm = choc_src_readableUtil.appendifyForm;;
var choc_src_readable = require("./../src/readable");
var readableNode = choc_src_readable.readableNode;
var readableJsStr = choc_src_readable.readableJsStr;
var generateReadableExpression = choc_src_readable.generateReadableExpression;
var compileMessage = choc_src_readable.compileMessage;
var annotationFor = choc_src_readable.annotationFor;;;

var assertMessage = function assertMessage(js, wanted, opts) {
  var parsed = first(parseJs(js));
  var selected = (opts || 0)["selector"] ?
    ((opts || 0)["selector"])(parsed) :
    parsed;
  var readable = readableNode(selected, opts);
  var transpiled = transpile(readable);
  var _ = puts(transpiled);
  var safeJs = "" + "try { " + js + " } catch(err) { \n          if(err.message != \"pause\") {\n            throw err;\n          }\n        }";
  (opts || 0)["before"] ?
    eval((opts || 0)["before"]) :
    void(0);
  eval(safeJs);
  eval("" + "var __msg = " + transpiled);
  (function() {
    (!(typeof(__verbose__) === "undefined")) && __verbose__ ?
      console.log("Assert:", "(identical? (:message (first __msg)) wanted)") :
      void(0);
    return !(((first(__msg)) || 0)["message"] === wanted) ?
      (function() { throw new Error("" + "Assert failed: " + ("" + "message does not equal '" + wanted + "'") + "\n\nAssertion:\n\n" + "(identical? (:message (first __msg)) wanted)" + "\n\nActual:\n\n" + (((first(__msg)) || 0)["message"]) + "\n--------------\n", void(0)); })() :
      void(0);
  })();
  return console.log("");
};
exports.assertMessage = assertMessage;

console.log("variable declarations");

assertMessage("var i = 2", "Create the variable <span class='choc-variable'>i</span> and set it to <span class='choc-value'>2</span>");

console.log("variable declarations");

assertMessage("var i", "Create the variable <span class='choc-variable'>i</span>");

console.log("variable declarations");

assertMessage("var fn = function() { return true; }", "Create the variable <span class='choc-variable'>fn</span> and set it to <span class='choc-value'>this function</span>");

console.log("AssignmentExpression");

assertMessage("foo = 1 + bar", "set foo to 3", {
  "before": "var bar = 2, foo = 0;"
});

console.log("AssignmentExpression");

assertMessage("fn = function() { return true; }", "set fn to this function", {
  "before": "var fn;"
});

console.log("WhileExpressions");

assertMessage("while (shift <= 200) {\n   throw new Error(\"pause\");\n }", "Because 4 is less than or equal to 200", {
  "before": "var shift = 4;"
});

assertMessage("while (shift <= 200) {\n   throw new Error(\"pause\");\n }", "Because 300 is not less than or equal to 200", {
  "before": "var shift = 300; var __cond = shift <= 200;",
  "hoistedName": "__cond"
});

console.log("BinaryExpressions");

assertMessage("foo += 1 + bar", "add 1 plus 2 to foo and set foo to 5", {
  "before": "var bar = 2, foo = 2, __hoist = 1 + bar;",
  "hoistedName": "__hoist"
});

assertMessage("foo *= 3", "multiply foo by 3 and set foo to 6", {
  "before": "var foo = 2;"
});

assertMessage("foo /= 3", "divide foo by 3 and set foo to 3", {
  "before": "var foo = 9;"
});

assertMessage("foo %= 3", "divide foo by 3 and set foo to the remainder: 2", {
  "before": "var foo = 8;"
});

assertMessage("bar + 1", "2 plus 1", {
  "before": "var bar = 2;"
});

assertMessage("bar == 1", "2 is equal to 1", {
  "before": "var bar = 2;"
});

assertMessage("bar < 1", "2 is not less than 1", {
  "before": "var bar = 2;",
  "negation": true
});

assertMessage("bar != 1", "2 is not equal to 1", {
  "before": "var bar = 2;"
});

assertMessage("bar * 1", "2 times 1", {
  "before": "var bar = 2;"
});

assertMessage("apple(\"hello\")", "call the function apple", {
  "before": "function apple() { return true; }"
});

console.log("CallExpression");

assertMessage("console.log(\"hello\")", "call the function console.log");

assertMessage("foo.bar.baz(10)", "call the function foo.bar.baz", {
  "before": "\n   var foo = {};\n   foo.bar = {};\n   foo.bar.baz = function(n) { return true; }"
});

assertMessage("annotatedfn(\"hello\", name, shift)", "I was annotated with hello, bob, 3", {
  "before": "\n   var shift = 3;\n   var name = \"bob\";\n   var annotatedfn = function() { return true; }; \n   var that = this;\n   annotatedfn.__choc_annotation = function(args) {\n     return \"I was annotated with \" + args[0] + \", \" + args[1] + \", \" + args[2] ;\n   }"
});

assertMessage("z.addAnimal(animal);", "Add a zebra to the zoo", {
  "before": "\n   function Zoo() { }\n   Zoo.prototype.addAnimal = function(animal) { return animal; }\n   Zoo.prototype.__choc_annotations = {\n     \"addAnimal\": function(args) {\n       puts(inspect(args));\n       return \"Add a \" + args[0] + \" to the zoo\";\n     }\n   };\n   var z = new Zoo();\n   var animal = \"zebra\";\n"
});

assertMessage("annotatedfn(shift + 2)", "I was called with 5", {
  "before": "\n   var shift = 3;\n   var annotatedfn = function(x) { return true; }; \n   var myeval = function(str) { eval(str); }\n   \n   var that = this;\n   annotatedfn.__choc_annotation = function(args) {\n     return \"I was called with \" + args[0];\n\n   }"
});

assertMessage("function apple() { return (1 + 2); }", "return 3", {
  "before": "var __hoist = 3;",
  "hoistedName": "__hoist",
  "selector": function(node) {
    return first((((node || 0)["body"]) || 0)["body"]);
  }
});

assertMessage("if( (x*x) + (y*y) <= (radius*radius) ) {\n   console.log(x, y);\n }", "Because 1 times 1 plus 4 times 4 is less than or equal to 5 times 5", {
  "before": "var radius=5, x=1, y=4;"
})