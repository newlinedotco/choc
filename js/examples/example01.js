// Generated by CoffeeScript 1.6.3
(function() {
  var choc, escodegen, esmorph, esprima, inspect, puts, scrubNotify, source, source_todo, _, _ref;

  _ref = require("util"), puts = _ref.puts, inspect = _ref.inspect;

  esprima = require("esprima");

  escodegen = require("escodegen");

  esmorph = require("esmorph");

  _ = require("underscore");

  choc = require("../src/choc");

  if ((typeof require !== "undefined" && require !== null) && (require.main === module)) {
    source_todo = "function add(a, b) {\n  var c = 3;\n  return a + b;\n}\n\nvar sub = function(a, b) {\n  var c = 3;\n  return a - b;\n}\nwhile (shift <= 200) {\n  // console.log(shift);\n  var x = add(1, shift);\n  shift += 14; // increment\n}";
    source = "// Life, Universe, and Everything\nvar answer = 6 * 7, question = 3;\nvar foo = \"bar\";\nconsole.log(answer); console.log(foo);\n\n// parabolas\nvar shift = 0;\nwhile (shift <= 200) {\n  // console.log(shift);\n  var foo = shift;\n  foo = shift - 1;\n  shift += 14; // increment\n}";
    scrubNotify = function(info) {
      return puts(inspect(info));
    };
    choc.scrub(source, 10, {
      notify: scrubNotify
    });
  }

}).call(this);