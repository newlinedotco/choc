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
  function add(a, b) {
    var c = 3;
    return a + b;
  }
  """

  source = """
  // parabolas
  var shift = 0;
  while (shift <= 200) {
    // console.log(shift);
    var foo = shift;
    if(foo % 2 == 0) {
      foo = shift - 1;
    }
    shift += 14; // increment
    foo = 1;
  }
  """

  source = """
    var radius = 5; 
    var x = 1;
    var y = 2;

    if( (x*x) + (y*y) <= (radius*radius) ) {
      console.log(x, y);
    }
  """

  scrubNotify = (info) ->
    puts inspect info

  # puts choc._hoist(source)
  puts choc.scrub(source, 10, notify: scrubNotify)

