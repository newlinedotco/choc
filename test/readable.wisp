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
            [choc.src.readable :refer [readable-node compile-readable-entries readable-js-str]]
            ))

(defn assert-message [js wanted & opts]
  (let [o (apply dictionary opts)
        parsed (first (parse-js js))
        ; _ (pp parsed)
        readable (readable-node parsed)
        _ (print (.to-string readable))
        compiled (first (compile-readable-entries readable))
        _ (pp compiled)
        transpiled (transpile compiled)
        _ (puts transpiled) 
        safe-js (str "try { " js " } catch(err) { 
          if(err.message != \"pause\") {
            throw err;
          }
        }")
        ]
    (if (.hasOwnProperty o :before) (eval (:before o)))
    (eval safe-js)
    (eval (str "var __msg = " transpiled))
    (assert (identical? (:message __msg) wanted) (str "message does not equal '" wanted "'")))
    (print (str "✓ " wanted)))

(defn assert-message-code [js wanted & opts]
  (let [o (apply dictionary opts)
        code (readable-js-str (first (parse-js js)))]
    (assert (identical? code wanted) (str "code does not equal '" wanted "'"))))


;; (print "variable declarations")
;; (assert-message 
;;  "var i = 2" 
;;  "Create the variable <span class='choc-variable'>i</span> and set it to <span class='choc-value'>2</span>")

;; (print "AssignmentExpression")
;; (assert-message 
;;  "foo = 1 + bar" 
;;  "set foo to 3"
;;  :before "var bar = 2, foo = 0;")

(print "while statements")

(assert-message 
 "while (shift <= 200) {
   throw new Error(\"pause\");
 }" 
 "Because 4 is less than or equal to 200"
 :before "var shift = 4;")

;; (assert-message 
;;  "while (shift <= 200) {
;;    throw new Error(\"pause\");
;;  }" 
;;  "Because 300 is not less than or equal to 200"
;;  :before "var shift = 300;")


;(print (.to-string (appendify-form `())))


;; --------------

;; (print "handling unknowns")
; (assert-message-code "a += 1" "[]")

;; (assert-message 
;;  "foo += 1 + bar" 
;;  "add 3 to foo and set foo to 5"
;;  :before "var bar = 2, foo = 2;")

;; (assert-message 
;;  "bar + 1" 
;;  ""
;;  :before "var bar = 2;")

;; (assert-message 
;;  "console.log(\"hello\")" 
;;  "asdf")

; "3 >= a"

; while(shift <= 200) {
;
; 



;; it 'function calls with annotations', () ->
;;   before = """
;;   annotatedfn = () ->
;;   annotatedfn.__choc_annotation = (args) ->
;;     return "'i was annotated with ' + " + "'" + readable.generateReadableExpression(args[0]) + "'"
;;   """
;;   before = coffee.compile(before, bare: true)
;;   code = "annotatedfn('hello')"
;;   result = messageE(code, before: before)
;;   result[0].message.should.eql 'i was annotated with hello'

;; it 'return statements', () ->
;;   code =  """
;;   function a() {
;;     return(1 + 2);
;;   }
;;   """
;;   pp message(code)

;; it 'member functions', () ->
;;   code = """
;;     var bob = {}
;;     bob.add = function(a, b){
;;       return a + b;
;;     }

;;     var x = bob.add(1, 2) + bob.add(3, 4);
;;     var y = x;
;;   """

;;   pp message(code)

