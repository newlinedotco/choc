var _ns_ = {
  "id": "choc.readable.util"
};
var wisp_ast = require("wisp/ast");
var symbol = wisp_ast.symbol;
var keyword = wisp_ast.keyword;;
var wisp_sequence = require("wisp/sequence");
var cons = wisp_sequence.cons;
var conj = wisp_sequence.conj;
var list = wisp_sequence.list;
var isList = wisp_sequence.isList;
var seq = wisp_sequence.seq;
var vec = wisp_sequence.vec;
var isEmpty = wisp_sequence.isEmpty;
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
var isSequential = wisp_sequence.isSequential;
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
var compileProgram = wisp_compiler.compileProgram;
var installMacro = wisp_compiler.installMacro;;
var wisp_reader = require("wisp/reader");
var readFromString = wisp_reader.readFromString;;
var esprima = require("esprima");;
var underscore = require("underscore");
var has = underscore.has;;
var util = require("util");
var puts = util.puts;
var inspect = util.inspect;;;

var toSet = function toSet(col) {
  var pairs = reduce(function(acc, item) {
    return concat(acc, [item, true]);
  }, [], col);
  return dictionary.apply(dictionary, vec(pairs));
};
exports.toSet = toSet;

var isSetIncl = function isSetIncl(set, key) {
  return set.hasOwnProperty(key);
};
exports.isSetIncl = isSetIncl;

var pp = function pp(form) {
  return puts(inspect(form, null, 100, true));
};
exports.pp = pp;

var transpile = function transpile() {
  var forms = Array.prototype.slice.call(arguments, 0);
  return compileProgram(forms);
};
exports.transpile = transpile;

var flattenOnce = function flattenOnce(lists) {
  return reduce(function(acc, item) {
    return concat(acc, item);
  }, lists);
};
exports.flattenOnce = flattenOnce;

var partition = function partition(n, step, pad, coll) {
  switch (arguments.length) {
    case 2:
      var coll = step;
      return partition(n, n, coll);
    case 3:
      var coll = pad;
      return (function loop(result, items) {
        var recur = loop;
        while (recur === loop) {
          recur = (function() {
          var group = take(n, items);
          return isEqual(n, count(group)) ?
            (result = conj(result, group), items = drop(step, items), loop) :
            result;
        })();
        };
        return recur;
      })([], coll);
    case 4:
      return partition(n, step, concat(coll, pad));

    default:
      (function() { throw Error("Invalid arity"); })()
  };
  return void(0);
};
exports.partition = partition;

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

undefined;

var appendifyFormOld = function appendifyFormOld(items) {
  return first(reduce(function(acc, item) {
    return list(cons(symbol(void(0), "+"), concat(acc, isList(item) ?
      list(appendifyForm(item)) :
      list(item))));
  }, list(first(items)), rest(items)));
};
exports.appendifyFormOld = appendifyFormOld;

var appendifyForm = function appendifyForm(items) {
  return isEqual(first(items), symbol(void(0), "fn")) ?
    list(items) :
    (function() {
      var head = first(items);
      var prefix = isList(head) ?
        appendifyForm(head) :
        head;
      var results = first(reduce(function(acc, item) {
        return list(cons(symbol(void(0), "+"), concat(acc, isList(item) ?
          list(appendifyForm(item)) :
          list(item))));
      }, list(prefix), rest(items)));
      return results;
    })();
};
exports.appendifyForm = appendifyForm;

var appendifyToStr = function appendifyToStr(items) {
  return reduce(function(acc, item) {
    return acc + (isList(item) ?
      appendifyToStr(item) :
      item);
  }, "", items);
};
exports.appendifyToStr = appendifyToStr