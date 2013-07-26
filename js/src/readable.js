var _ns_ = {
  "id": "choc.readable"
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
var choc_readable_util = require("./util");
var toSet = choc_readable_util.toSet;
var isSetIncl = choc_readable_util.isSetIncl;
var partition = choc_readable_util.partition;
var pp = choc_readable_util.pp;
var transpile = choc_readable_util.transpile;
var flattenOnce = choc_readable_util.flattenOnce;
var parseJs = choc_readable_util.parseJs;
var appendifyForm = choc_readable_util.appendifyForm;
var when = choc_readable_util.when;;;

undefined;

var generateReadableValue = function generateReadableValue(node1, node2, opts) {
  switch (arguments.length) {
    case 2:
      return generateReadableValue(node1, node2, {});
    case 3:
      return node1.hasOwnProperty("name") ?
        symbol((node1 || 0)["name"]) :
      isEqual("FunctionExpression", (node2 || 0)["type"]) ?
        "this function" :
      "else" ?
        "TODO" :
        void(0);

    default:
      (function() { throw Error("Invalid arity"); })()
  };
  return void(0);
};
exports.generateReadableValue = generateReadableValue;

var generateReadableExpression = function generateReadableExpression(node) {
  switch (arguments.length) {
    case 1:
      return generateReadableExpression(node, {});

    default:
      var opts = Array.prototype.slice.call(arguments, 1);
      pp(node);
      return (function() {
        var o = dictionary.apply(dictionary, opts);
        var type = (node || 0)["type"];
        var op = (node || 0)["operator"];
        return isEqual(type, "AssignmentExpression") ?
          isEqual("=", op) ?
            list("set ", generateReadableExpression((node || 0)["left"], "want", "name"), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
          isEqual("+=", op) ?
            list("add ", generateReadableExpression((node || 0)["right"]), " to ", generateReadableExpression((node || 0)["left"], "want", "name"), " and set ", generateReadableExpression((node || 0)["left"], "want", "name"), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
            void(0) :
        isEqual(type, "BinaryExpression") ?
          (function() {
            return void(0);
          })() :
        isEqual(type, "CallExpression") ?
          (function() {
            console.log("CALLEXPRESS");
            return list(list(list(symbol(void(0), "fn"), [], list(symbol(void(0), "if"), true, list(symbol(void(0), "list"), "tell foo to bar")))));
          })() :
        isEqual(type, "MemberExpression") ?
          (function() {
            console.log("MEMBER");
            pp(node);
            return list("TODO");
          })() :
        isEqual(type, "Literal") ?
          (node || 0)["value"] :
        isEqual(type, "Identifier") ?
          isEqual((o || 0)["want"], "name") ?
            (node || 0)["name"] :
            symbol((node || 0)["name"]) :
          void(0);
      })();
  };
  return void(0);
};
exports.generateReadableExpression = generateReadableExpression;

var readableNode = function readableNode(node, opts) {
  switch (arguments.length) {
    case 1:
      return readableNode(node, {});
    case 2:
      pp(node);
      return (function() {
        var t = (node || 0)["type"];
        return isEqual("VariableDeclaration", t) ?
          map(function(dec) {
            var name = (dec.id).name;
            return list("lineNumber", ((node.loc).start).line, "message", list("" + "Create the variable <span class='choc-variable'>" + name + "</span> and set it to <span class='choc-value'>", symbol(name), "</span>"), "timeline", symbol(name));
          }, node.declarations) :
        isEqual("ExpressionStatement", t) ?
          (function() {
            var expression = (generateReadableExpression((node || 0)["expression"])) || (list(""));
            return list(list("lineNumber", ((node.loc).start).line, "message", expression));
          })() :
        "else" ?
          (function() {
            pp("its else");
            pp(node);
            return list();
          })() :
          void(0);
      })();

    default:
      (function() { throw Error("Invalid arity"); })()
  };
  return void(0);
};
exports.readableNode = readableNode;

var compileMessage = function compileMessage(message) {
  return isSymbol(message) ?
    message :
  isKeyword(message) ?
    "" + (ast.name(message)) :
  isList(message) ?
    appendifyForm(message) :
  "else" ?
    message :
    void(0);
};
exports.compileMessage = compileMessage;

var compileReadableEntry = function compileReadableEntry(node) {
  var compiledPairs = map(function(pair) {
    var k = first(pair);
    var v = second(pair);
    var strKey = "" + (ast.name(k));
    var compiledMessage = compileMessage(v);
    return list(strKey, compiledMessage);
  }, partition(2, node));
  var flat = flattenOnce(compiledPairs);
  var asDict = dictionary.apply(dictionary, vec(flat));
  return asDict;
};
exports.compileReadableEntry = compileReadableEntry;

var compileReadableEntries = function compileReadableEntries(nodes) {
  return isEmpty(nodes) ?
    [] :
    map(compileReadableEntry, nodes);
};
exports.compileReadableEntries = compileReadableEntries;

var readableJsStr = function readableJsStr(node) {
  var readable = readableNode(node);
  var compiled = compileReadableEntries(readable);
  var transpiled = transpile(compiled);
  return transpiled;
};
exports.readableJsStr = readableJsStr