var _ns_ = {
  "id": "choc.readable.util"
};
var wisp_src_ast = require("wisp/src/ast");
var symbol = wisp_src_ast.symbol;
var keyword = wisp_src_ast.keyword;;
var wisp_src_sequence = require("wisp/src/sequence");
var cons = wisp_src_sequence.cons;
var conj = wisp_src_sequence.conj;
var list = wisp_src_sequence.list;
var isList = wisp_src_sequence.isList;
var seq = wisp_src_sequence.seq;
var vec = wisp_src_sequence.vec;
var isEmpty = wisp_src_sequence.isEmpty;
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
var compileProgram = wisp_src_compiler.compileProgram;;
var wisp_src_reader = require("wisp/src/reader");
var readFromString = wisp_src_reader.readFromString;;
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
exports.partition = partition