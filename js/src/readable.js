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
var escodegen = require("escodegen");;
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
      true ?
        generateReadableExpression(node2) :
      "else" ?
        "" :
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
          isEqual("-=", op) ?
            list("subtract ", generateReadableExpression((node || 0)["right"]), " from ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " and set ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
          isEqual("*=", op) ?
            list("multiply ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " by ", generateReadableExpression((node || 0)["right"]), " and set ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
          isEqual("/=", op) ?
            list("divide ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " by ", generateReadableExpression((node || 0)["right"]), " and set ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " to ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
          isEqual("%=", op) ?
            list("divide ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " by ", generateReadableExpression((node || 0)["right"]), " and set ", generateReadableExpression((node || 0)["left"], {
              "want": "name"
            }), " to the remainder: ", generateReadableValue((node || 0)["left"], (node || 0)["right"])) :
            void(0) :
        isEqual(type, "BinaryExpression") ?
          (function() {
            var truthy = function(node, verbiage) {
              return list(generateReadableExpression((node || 0)["left"]), isOrNot, verbiage, generateReadableExpression((node || 0)["right"]));
            };
            var opy = function(node, verbiage) {
              return list(generateReadableExpression((node || 0)["left"]), verbiage, generateReadableExpression((node || 0)["right"]));
            };
            return isEqual("+", op) ?
              opy(node, " plus ") :
            isEqual("-", op) ?
              opy(node, " minus ") :
            isEqual("*", op) ?
              opy(node, " times ") :
            isEqual("/", op) ?
              opy(node, " divided by ") :
            isEqual("%", op) ?
              opy(node, " modulo ") :
            isEqual("|", op) ?
              opy(node, " bitwise-or ") :
            isEqual("^", op) ?
              opy(node, " bitwise-and ") :
            isEqual("<=", op) ?
              truthy(node, " less than or equal to ") :
            isEqual("==", op) ?
              truthy(node, " equal to ") :
            isEqual("===", op) ?
              truthy(node, " equal to ") :
            isEqual("!=", op) ?
              truthy(node, " not equal to ") :
            isEqual("<", op) ?
              truthy(node, " less than ") :
            isEqual("<=", op) ?
              truthy(node, " less than or equal to ") :
            isEqual(">", op) ?
              truthy(node, " greater than ") :
            isEqual(">=", op) ?
              truthy(node, " greater than or equal to ") :
            true ?
              "" + "" :
              void(0);
          })() :
        isEqual(type, "ObjectExpression") ?
          list("an object") :
        isEqual(type, "CallExpression") ?
          (isEqual(node.callee ?
            (node.callee).type :
            void(0), "Identifier")) || (isEqual(node.callee ?
            (node.callee).type :
            void(0), "MemberExpression")) ?
            (function() {
              var calleeExpression = generateReadableExpression(node.callee, {
                "want": "name"
              });
              var calleeCompiled = compileMessage(calleeExpression);
              var calleeObject = generateReadableExpression(node.callee ?
                (node.callee).object :
                void(0), {
                "want": "name"
              });
              var calleeObjectCompiled = compileMessage(calleeObject);
              var propertyN = (node.callee).property ?
                ((node.callee).property).name :
                void(0);
              var argumentSources = map(function(arg) {
                return escodegen.generate(arg, {
                  "format:": {
                    "compact:": false
                  }
                });
              }, node.arguments);
              return list(list(list(symbol(void(0), "fn"), [], list(symbol(void(0), "let"), vec([symbol(void(0), "callee"), list(symbol(void(0), "eval"), calleeCompiled), symbol(void(0), "callee-object"), list(symbol(void(0), "eval"), calleeObjectCompiled), symbol(void(0), "arguments"), list(symbol("wisp.sequence", "map"), list(symbol(void(0), "fn"), vec([symbol(void(0), "arg")]), list(symbol(void(0), "eval"), symbol(void(0), "arg"))), argumentSources)]), list(symbol("readable", "annotation-for"), symbol(void(0), "callee"), symbol(void(0), "callee-object"), calleeCompiled, propertyN, symbol(void(0), "arguments"))))));
            })() :
          true ?
            "" :
            void(0) :
        isEqual(type, "MemberExpression") ?
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
        isEqual("IfStatement", t) ?
          (function() {
            var conditional = (o || 0)["hoistedName"] ?
              symbol((o || 0)["hoistedName"]) :
              true;
            var trueMessages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", list("Because ", generateReadableExpression((node || 0)["test"])), "timeline", "t"))];
            var falseMessages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", list("Skip because ", generateReadableExpression((node || 0)["test"], {
              "negation": true
            })), "timeline", "f"))];
            return list(list(symbol(void(0), "fn"), vec([symbol(void(0), "condition")]), list(symbol(void(0), "if"), symbol(void(0), "condition"), trueMessages, falseMessages)), conditional);
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
              void(0), "message", generateReadableExpression((node || 0)["expression"], opts)))];
            return list(list(symbol(void(0), "fn"), [], messages));
          })() :
        isEqual("ReturnStatement", t) ?
          (function() {
            var messages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", list("return ", symbol((o || 0)["hoistedName"])), "timeline", symbol((o || 0)["hoistedName"])))];
            return list(list(symbol(void(0), "fn"), [], messages));
          })() :
        isEqual("CallExpression", t) ?
          (function() {
            var messages = [compileEntry(list("lineNumber", (node.loc).start ?
              ((node.loc).start).line :
              void(0), "message", generateReadableExpression(node, opts)))];
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

var readableJsStr = function readableJsStr(node, opts) {
  var readable = readableNode(node, opts);
  var transpiled = transpile(readable);
  var result = readable ?
    transpiled :
    "''";
  return result;
};
exports.readableJsStr = readableJsStr;

var findAnnotationFor = function findAnnotationFor(obj, propertyName, args) {
  var proto = (obj.constructor).prototype;
  return obj.hasOwnProperty("__choc_annotation") ?
    obj.__choc_annotation(args) :
  (obj.hasOwnProperty("__choc_annotations")) && ((obj || 0)["__choc_annotations"].hasOwnProperty(propertyName)) ?
    ((((obj || 0)["__choc_annotations"]) || 0)[propertyName])(args) :
  (proto.hasOwnProperty("__choc_annotations")) && ((proto || 0)["__choc_annotations"].hasOwnProperty(propertyName)) ?
    ((((proto || 0)["__choc_annotations"]) || 0)[propertyName])(args) :
  true ?
    false :
    void(0);
};
exports.findAnnotationFor = findAnnotationFor;

var annotationFor = function annotationFor(callee, calleeObject, calleeCompiled, propertyName, args) {
  var calleeAnnotation = findAnnotationFor(callee, propertyName, args);
  return calleeAnnotation ?
    calleeAnnotation :
    (function() {
      var calleeObjectAnnotation = calleeObject ?
        findAnnotationFor(calleeObject, propertyName, args) :
        false;
      return calleeObjectAnnotation ?
        calleeObjectAnnotation :
        "" + "call the function " + calleeCompiled;
    })();
};
exports.annotationFor = annotationFor