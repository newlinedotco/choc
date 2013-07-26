var _ns_ = {
  "id": "choc.readable"
};
var ast = require("wisp/src/ast");
var symbol = ast.symbol;
var keyword = ast.keyword;
var isSymbol = ast.isSymbol;
var isKeyword = ast.isKeyword;;
var wisp_src_sequence = require("wisp/src/sequence");
var cons = wisp_src_sequence.cons;
var conj = wisp_src_sequence.conj;
var list = wisp_src_sequence.list;
var isList = wisp_src_sequence.isList;
var seq = wisp_src_sequence.seq;
var vec = wisp_src_sequence.vec;
var isEmpty = wisp_src_sequence.isEmpty;
var isSequential = wisp_src_sequence.isSequential;
var count = wisp_src_sequence.count;
var first = wisp_src_sequence.first;
var second = wisp_src_sequence.second;
var third = wisp_src_sequence.third;
var rest = wisp_src_sequence.rest;
var last = wisp_src_sequence.last;
var butlast = wisp_src_sequence.butlast;
var take = wisp_src_sequence.take;
var drop = wisp_src_sequence.drop;
var repeat = wisp_src_sequence.repeat;
var concat = wisp_src_sequence.concat;
var reverse = wisp_src_sequence.reverse;
var sort = wisp_src_sequence.sort;
var map = wisp_src_sequence.map;
var filter = wisp_src_sequence.filter;
var reduce = wisp_src_sequence.reduce;
var assoc = wisp_src_sequence.assoc;;
var wisp_src_runtime = require("wisp/src/runtime");
var str = wisp_src_runtime.str;
var isEqual = wisp_src_runtime.isEqual;
var dictionary = wisp_src_runtime.dictionary;;
var wisp_src_compiler = require("wisp/src/compiler");
var isSelfEvaluating = wisp_src_compiler.isSelfEvaluating;
var compile = wisp_src_compiler.compile;
var macroexpand = wisp_src_compiler.macroexpand;
var macroexpand1 = wisp_src_compiler.macroexpand1;
var compileProgram = wisp_src_compiler.compileProgram;;
var wisp_src_reader = require("wisp/src/reader");
var readFromString = wisp_src_reader.readFromString;;
var esprima = require("esprima");;
var underscore = require("underscore");
var has = underscore.has;;
var util = require("util");
var puts = util.puts;
var inspect = util.inspect;;
var choc_readable_util = require("./util");
var toSet = choc_readable_util.toSet;
var isSetIncl = choc_readable_util.isSetIncl;
var partition = choc_readable_util.partition;;;

undefined;

var flattenOnce = function flattenOnce(lists) {
  return reduce(function(acc, item) {
    return concat(acc, item);
  }, lists);
};
exports.flattenOnce = flattenOnce;

var transpile = function transpile() {
  var forms = Array.prototype.slice.call(arguments, 0);
  return compileProgram(forms);
};
exports.transpile = transpile;

var pp = function pp(form) {
  return puts(inspect(form, null, 100, true));
};
exports.pp = pp;

var parseJs = function parseJs(code, opts) {
  switch (arguments.length) {
    case 1:
      return parseJs(code, {
        "range": true,
        "loc": true
      });
    case 2:
      return (function() {
        var program = esprima.parse(code, opts);
        return (program || 0)["body"];
      })();

    default:
      (function() { throw Error("Invalid arity"); })()
  };
  return void(0);
};
exports.parseJs = parseJs;

var pjs = function pjs(code) {
  return first(parseJs(code));
};
exports.pjs = pjs;

var readableNode = function readableNode(node, opts) {
  switch (arguments.length) {
    case 1:
      return readableNode(node, {});
    case 2:
      return isEqual((node || 0)["type"], "VariableDeclaration") ?
        map(function(dec) {
          var name = (dec.id).name;
          return list("꞉lineNumber", ((node.loc).start).line, "꞉message", list("" + "Create the variable <span class='choc-variable'>" + name + "</span> and set it to <span class='choc-value'>", symbol(name), "</span>"), "꞉timeline", symbol(name));
        }, node.declarations) :
      "else" ?
        (function() {
          pp("its else");
          return pp(node);
        })() :
        void(0);

    default:
      (function() { throw Error("Invalid arity"); })()
  };
  return void(0);
};
exports.readableNode = readableNode;

undefined;

var compileMessage = function compileMessage(message) {
  return isSymbol(message) ?
    message :
  isKeyword(message) ?
    "" + (ast.name(message)) :
  isList(message) ?
    first(reduce(function(acc, item) {
      return list(cons(symbol(void(0), "+"), concat(acc, list(item))));
    }, list(first(message)), rest(message))) :
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
  return map(compileReadableEntry, nodes);
};
exports.compileReadableEntries = compileReadableEntries;

(function() {
  var readable = readableNode(pjs("var i = 0, j = 1;"));
  console.log(readable.toString());
  compileReadableEntries(readable);
  return console.log(transpile(compileReadableEntries(readable)));
})();

console.log("\n\n")