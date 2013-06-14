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
  var foo = 1;
  var bar = foo + 2 < 3;
  if(foo + 2 < 3) {
    console.log('it is');
  }
  console.log(foo);
  """

  source = """
  var foo = 1;
  if(foo + 2 < 3) {
    console.log('it is');
  }
  """

  scrubNotify = (info) ->
    puts inspect info

  # choc.scrub(source, 10, notify: scrubNotify)
  puts choc._hoist(source)

