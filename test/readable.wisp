(ns choc.test.readable
  (:require [wisp.ast :as ast :refer [symbol keyword symbol? keyword?]]
            [wisp.sequence :refer [cons conj list list? seq vec empty? sequential?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse
                                       sort map filter reduce assoc]]
            [wisp.runtime :refer [str = dictionary]]
            [wisp.compiler :refer [self-evaluating? compile macroexpand macroexpand-1
                                       compile-program]]
            [wisp.reader :refer [read-from-string]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]
            [choc.src.util :refer [to-set set-incl? partition transpile pp parse-js when appendify-form]]
            [choc.src.readable :refer [readable-node compile-readable-entries readable-js-str generate-readable-expression readable-args readable-arg]]
            ))

(defn assert-message [js wanted opts]
  (let [;o (apply dictionary (vec opts))
        parsed (first (parse-js js))
        selected (if (:selector opts) ((:selector opts) parsed) parsed)
        readable (readable-node selected opts)
        transpiled (transpile readable)
        _ (puts transpiled) 
        safe-js (str "try { " js " } catch(err) { 
          if(err.message != \"pause\") {
            throw err;
          }
        }")
        ]
    (if (:before opts) (eval (:before opts)))
    (eval safe-js)
    (eval (str "var __msg = " transpiled))
    (assert (identical? (:message (first __msg)) wanted) (str "message does not equal '" wanted "'"))
    (print "")
    ))

;; (print "variable declarations")
;; (assert-message 
;;  "var i = 2" 
;;  "Create the variable <span class='choc-variable'>i</span> and set it to <span class='choc-value'>2</span>")

;; (assert-message 
;;  "var i = {foo: 2};" 
;;  "Create the variable <span class='choc-variable'>i</span> and set it to <span class='choc-value'>an object</span>")

;; (print "AssignmentExpression")
;; (assert-message 
;;  "foo = 1 + bar" 
;;  "set foo to 3"
;;  {:before "var bar = 2, foo = 0;"})

;; (print "WhileExpressions")
;; (assert-message 
;;  "while (shift <= 200) {
;;    throw new Error(\"pause\");
;;  }" 
;;  "Because 4 is less than or equal to 200"
;;  {:before "var shift = 4;"})

;; (assert-message 
;;  "while (shift <= 200) {
;;    throw new Error(\"pause\");
;;  }" 
;;  "Because 300 is not less than or equal to 200"
;;  {:before "var shift = 300; var __cond = shift <= 200;"
;;   :hoistedName "__cond"})

;; (print "BinaryExpressions")
;; (assert-message 
;;  "foo += 1 + bar" 
;;  "add 1 plus 2 to foo and set foo to 5" ; <-- desired text?
;;  {:before "var bar = 2, foo = 2, __hoist = 1 + bar;"
;;   :hoistedName "__hoist"})

;; (assert-message 
;;  "foo *= 3" 
;;  "multiply foo by 3 and set foo to 6"
;;  {:before "var foo = 2;"})

;; (assert-message 
;;  "foo /= 3" 
;;  "divide foo by 3 and set foo to 3"
;;  {:before "var foo = 9;"})

;; (assert-message 
;;  "foo %= 3" 
;;  "divide foo by 3 and set foo to the remainder: 2"
;;  {:before "var foo = 8;"})

;; (assert-message 
;;  "bar + 1" 
;;  "2 plus 1" ; <- desired?
;;  {:before "var bar = 2;"})

;; (assert-message 
;;  "bar == 1" 
;;  "2 is equal to 1"
;;  {:before "var bar = 2;"})

;; (assert-message 
;;  "bar < 1" 
;;  "2 is not less than 1"
;;  {:before "var bar = 2;"
;;   :negation true})

;; (assert-message 
;;  "bar != 1" 
;;  "2 is not equal to 1"
;;  {:before "var bar = 2;"})

;; (assert-message 
;;  "bar * 1" 
;;  "2 times 1"
;;  {:before "var bar = 2;"})

;; (assert-message 
;;  "apple(\"hello\")" 
;;  "call the function apple"
;; {:before "function apple() { return true; }"})

;; (print "CallExpression")
;; (assert-message 
;;  "console.log(\"hello\")" 
;;  "call the function console.log")

;; (assert-message
;;  "foo.bar.baz(10)"
;;  "call the function foo.bar.baz"
;;  {:before "
;;    var foo = {};
;;    foo.bar = {};
;;    foo.bar.baz = function(n) { return true; }"
;;   })

;; (assert-message 
;;  "annotatedfn(\"hello\", shift)" 
;;  "I was annotated with hello, 3"
;;  {:before "
;;    var shift = 3;
;;    var annotatedfn = function() { return true; }; 

;;    var myeval = function(str) { eval(str); }
   
;;    var that = this;
;;    annotatedfn.__choc_annotation = function(args) {
;;      return \"I was annotated with \" + generateReadableExpression(args[0]) + 
;;       \", \" + eval(generateReadableExpression(args[1], {\"want\": \"name\"})) ;
;;    }"})

;; (assert-message 
;;  "z.addAnimal(animal);" 
;;  "Add a zebra to the zoo"
;;  {:before "
;;    function Zoo() { }
;;    Zoo.prototype.addAnimal = function(animal) { return animal; }
;;    Zoo.prototype.__choc_annotations = {
;;      \"addAnimal\": function(args) {
;;        animal = readableArg(args[0]);
;;        return \"Add a \" + animal + \" to the zoo\";
;;      }
;;    };
;;    z = new Zoo();
;;    animal = \"zebra\";
;; "})

;; (assert-message 
;;  "line.width = 3;" 
;;  "set line.width = 3"
;;  {:before "var line = {width: 1};"})


;; (assert-message 
;;  "function apple() { return (1 + 2); }" 
;;  "return 3"
;;  {:before "var __hoist = 3;"
;;   :hoistedName "__hoist"
;;   :selector (fn [node] (first (:body (:body node))))})



;; ---- TODOs below ----

;; (assert-message 
;;  "line.width = 3;" 
;;  "i'm setting width"
;;  {:before "
;;    var line = {width: 1};
;;    line.__choc_annotations = {
;;      \"width\": function(args) {
;;        return \"i'm setting width\";
;;      }
;;    };
;; "})

