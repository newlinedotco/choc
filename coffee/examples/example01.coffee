{puts,inspect} = require("util")
esprima = require("esprima")
escodegen = require("escodegen")
esmorph = require("esmorph")
_ = require("underscore")
choc = require("../src/choc")

if require? && (require.main == module)

  source_todo = """
  function add(a, b) {
    var c = 3;
    return a + b;
  }

  var sub = function(a, b) {
    var c = 3;
    return a - b;
  }
  while (shift <= 200) {
    // console.log(shift);
    var x = add(1, shift);
    shift += 14; // increment
  }
  """

  source = """
  // Life, Universe, and Everything
  var answer = 6 * 7, question = 3;
  var foo = "bar";
  console.log(answer); console.log(foo);

  // parabolas
  var shift = 0;
  while (shift <= 200) {
    // console.log(shift);
    var foo = shift;
    foo = shift - 1;
    shift += 14; // increment
  }
  """
  scrubNotify = (info) ->
    puts inspect info

  source = """
    var foo = "bar";
    console.log(1);
  """

  choc.scrub(source, 10, notify: scrubNotify)

