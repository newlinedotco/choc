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
var dictionary = wisp_runtime.dictionary;
var isDictionary = wisp_runtime.isDictionary;
var isFn = wisp_runtime.isFn;
var merge = wisp_runtime.merge;;
var wisp_compiler = require("wisp/compiler");
var isSelfEvaluating = wisp_compiler.isSelfEvaluating;
var compile = wisp_compiler.compile;
var macroexpand = wisp_compiler.macroexpand;
var macroexpand1 = wisp_compiler.macroexpand1;
var compileProgram = wisp_compiler.compileProgram;;
var wisp_reader = require("wisp/reader");
var readFromString = wisp_reader.readFromString;;
var str = require("wisp/string");
var join = str.join;;
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
var when = choc_readable_util.when;
var appendifyForm = choc_readable_util.appendifyForm;
var appendifyToStr = choc_readable_util.appendifyToStr;;;

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

var generateReadableExpression = function generateReadableExpression(node, opts) {
  switch (arguments.length) {
    case 1:
      return generateReadableExpression(node, {});
    case 2:
      return (function() {
        var o = opts;
        var _ = pp(["Generate readable expression", o, node]);
        var type = (node || 0)["type"];
        var op = (node || 0)["operator"];
        var isOrNot = (o || 0)["negation"] ?
          " is not" :
          " is";
        return isEqual(type, "AssignmentExpression") ?
          isEqual("=", op) ?
            list("set ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
          isEqual("+=", op) ?
            list("add ", generateReadableExpression((node || 0)["right"]), " to ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " and set ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
            void(0) :
        isEqual(type, "BinaryExpression") ?
          (function() {
            return isEqual("<=", op) ?
              list(generateReadableExpression((node || 0)["left"]), isOrNot, " less than or equal to ", generateReadableExpression((node || 0)["right"])) :
            isEqual("+", op) ?
              list(generateReadableExpression((node || 0)["left"]), " plus ", generateReadableExpression((node || 0)["right"])) :
              void(0);
          })() :
        isEqual(type, "CallExpression") ?
          (isEqual(node.callee ?
            (node.callee).type :
            void(0), "Identifier")) || (isEqual(node.callee ?
            (node.callee).type :
            void(0), "MemberExpression")) ?
            (function() {
              var calleeExpression = generateReadableExpression(node ?
                node.callee :
                void(0), {
                "want": "name",
                "callArguments": node.arguments
              });
              var calleeCompiled = compileMessage(calleeExpression);
              return list(list(list(symbol(void(0), "fn"), [], list(symbol(void(0), "cond"), list(symbol(void(0), ".hasOwnProperty"), list(symbol(void(0), "eval"), calleeCompiled), "__choc_annotation"), list(symbol(void(0), ".__choc_annotation"), list(symbol(void(0), "eval"), calleeCompiled), node.arguments), true, list(symbol(void(0), "str"), "call the function ", calleeCompiled)))));
            })() :
          true ?
            "" :
            void(0) :
        isEqual(type, "CallExpressionXX") ?
          (function() {
            var calleeExpression = generateReadableExpression(node ?
              node.callee :
              void(0));
            var target = (node.callee ?
              (node.callee).name :
              void(0)) || calleeExpression;
            node.callee ?
              (node.callee).object :
              void(0) ?
              list("tell ", generateReadableExpression(node.callee ?
                (node.callee).object :
                void(0), {
                "want": "name"
              }), " to ", generateReadableExpression(node.callee ?
                (node.callee).property :
                void(0), {
                "want": "name"
              })) :
            node.callee ?
              (node.callee).name :
              void(0) ?
              list("call the function ", generateReadableExpression(node ?
                node.callee :
                void(0), {
                "want": "name"
              })) :
              void(0);
            return list(list(list(symbol(void(0), "fn"), [], list(symbol(void(0), "let"), vec([symbol(void(0), "trg"), target]), list(symbol(void(0), "cond"), list(symbol(void(0), ".hasOwnProperty"), symbol(void(0), "trg"), "__choc_annotation"), list(symbol(void(0), ".__choc_annotation"), symbol(void(0), "trg"), node.arguments), node.callee ?
              (node.callee).name :
              void(0) ?
              true :
              false, list(symbol(void(0), "str"), "call the function ", node.callee ?
              (node.callee).name :
              void(0)), (node.callee).object ?
              ((node.callee).object).name :
              void(0) ?
              true :
              false, list(symbol(void(0), "str"), "tell ", (node.callee).object ?
              ((node.callee).object).name :
              void(0), " to ", (node.callee).property ?
              ((node.callee).property).name :
              void(0)), target ?
              true :
              false, list(symbol(void(0), "str"), "call ", symbol(void(0), "trg")), true, "")))));
          })() :
        isEqual(type, "MemberExpression") ?
          isEqual(node.object ?
            (node.object).type :
            void(0), "MemberExpression") ?
            list("", generateReadableExpression(node.object, {
              "want": "name"
            }), ".", generateReadableExpression(node.property, {
              "want": "name"
            })) :
            list("", generateReadableExpression(node.object, {
              "want": "name"
            }), ".", generateReadableExpression(node.property, {
              "want": "name"
            })) :
        isEqual(type, "Literal") ?
          (node || 0)["value"] :
        isEqual(type, "Identifier") ?
          isEqual((o || 0)["want"], "name") ?
            (node || 0)["name"] :
            symbol((node || 0)["name"]) :
        isEqual(type, "VariableDeclarator") ?
          isEqual((o || 0)["want"], "name") ?
            generateReadableExpression(node ?
              node.id :
              void(0), {
              "want": "name"
            }) :
          true ?
            generateReadableExpression(node ?
              node.id :
              void(0)) :
            void(0) :
        true ?
          list("") :
          void(0);
      })();

    default:
      (function() { throw Error("Invalid arity"); })()
  };
  return void(0);
};
exports.generateReadableExpression = generateReadableExpression;

var makeOpts = function makeOpts(opts) {
  return isDictionary(opts) ?
    opts :
    dictionary.apply(dictionary, vec(opts));
};
exports.makeOpts = makeOpts;

var readableNode = function readableNode(node, opts) {
  switch (arguments.length) {
    case 1:
      return readableNode(node, {});
    case 2:
      pp(node);
      return (function() {
        var o = makeOpts(opts);
        var t = (node || 0)["type"];
        return isEqual("VariableDeclaration", t) ?
          (function() {
            var messages = vec(map(function(dec) {
              var name = dec.id ?
                (dec.id).name :
                void(0);
              return compileEntry(list("lineNumber", (node.loc).start ?
                ((node.loc).start).line :
                void(0), "message", list("" + "Create the variable <span class='choc-variable'>" + name + "</span> and set it to <span class='choc-value'>", generateReadableExpression(dec), "</span>"), "timeline", symbol(name)));
            }, node.declarations));
            return list(list(symbol(void(0), "fn"), [], messages));
          })() :
        isEqual("WhileStatement", t) ?
          (function() {
            var conditional = (o || 0)["hoistedName"] ?
              symbol((o || 0)["hoistedName"]) :
              true;
            var trueMessages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", list("Because ", generateReadableExpression((node || 0)["test"])), "timeline", "t")), compileEntry(list("lineNumber", (node.loc).end ?
              ((node.loc).end).line :
              void(0), "message", list("... and try again"), "timeline", ""))];
            var falseMessages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", list("Because ", generateReadableExpression((node || 0)["test"], {
              "negation": true
            })), "timeline", "f")), compileEntry(list("lineNumber", (node.loc).end ?
              ((node.loc).end).line :
              void(0), "message", list("... stop looping"), "timeline", ""))];
            return list(list(symbol(void(0), "fn"), vec([symbol(void(0), "condition")]), list(symbol(void(0), "if"), symbol(void(0), "condition"), trueMessages, falseMessages)), conditional);
          })() :
        isEqual("ExpressionStatement", t) ?
          (function() {
            var messages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", generateReadableExpression((node || 0)["expression"])))];
            return list(list(symbol(void(0), "fn"), [], messages));
          })() :
        isEqual("ReturnStatement", t) ?
          (function() {
            var messages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", list("return ", symbol((o || 0)["hoistedName"]))))];
            return list(list(symbol(void(0), "fn"), [], messages));
          })() :
        isEqual("CallExpression", t) ?
          (function() {
            var messages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", generateReadableExpression(node)))];
            return list(list(symbol(void(0), "fn"), [], messages));
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

var compileEntry = function compileEntry(node) {
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
exports.compileEntry = compileEntry;

var compileReadableEntries = function compileReadableEntries(nodes) {
  return isFn(nodes) ?
    nodes :
  isEmpty(nodes) ?
    [] :
    map(compileEntry, nodes);
};
exports.compileReadableEntries = compileReadableEntries;

var readableJsStr = function readableJsStr(node, opts) {
  var readable = readableNode(node, opts);
  var transpiled = transpile(readable);
  var result = readable ?
    transpiled :
    "''";
  return result;
};
exports.readableJsStr = readableJsStr