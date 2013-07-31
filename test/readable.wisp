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
            [choc.src.readable :refer [readable-node compile-readable-entries readable-js-str generate-readable-expression]]
            ))

(defn assert-message [js wanted & opts]
  (let [o (apply dictionary opts)
        parsed (first (parse-js js))
        selected (if (:selector o) ((:selector o) parsed) parsed)
        readable (readable-node selected opts)
        transpiled (transpile readable)
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
    (assert (identical? (:message (first __msg)) wanted) (str "message does not equal '" wanted "'"))
    (print "")
    ))

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

;; (print "WhileExpressions")
;; (assert-message 
;;  "while (shift <= 200) {
;;    throw new Error(\"pause\");
;;  }" 
;;  "Because 4 is less than or equal to 200"
;;  :before "var shift = 4;")

;; (assert-message 
;;  "while (shift <= 200) {
;;    throw new Error(\"pause\");
;;  }" 
;;  "Because 300 is not less than or equal to 200"
;;  :before "var shift = 300; var __cond = shift <= 200;"
;;  :hoistedName '__cond)

;; (print "BinaryExpressions")
;; (assert-message 
;;  "foo += 1 + bar" 
;;  "add 1 plus 2 to foo and set foo to 5" ; <-- desired text?
;;  :before "var bar = 2, foo = 2, __hoist = 1 + bar;"
;;  :hoistedName "__hoist")

;; (assert-message 
;;  "bar + 1" 
;;  "2 plus 1" ; <- desired?
;;  :before "var bar = 2;")

;; (print "CallExpression")
;; (assert-message 
;;  "console.log(\"hello\")" 
;;  "tell console to log")

;; (assert-message 
;;  "apple(\"hello\")" 
;;  "call the function apple"
;;  :before "function apple() { return true; }")

;; (assert-message 
;;  "annotatedfn(\"hello\")" 
;;  "I was annotated with hello"
;;  :before "var annotatedfn = function() { return true; }; 
;;           annotatedfn.__choc_annotation = function(args) {
;;             return \"I was annotated with \" + generateReadableExpression(args[0]);
;;           }")


;; (assert-message 
;;  "function apple() { return (1 + 2); }" 
;;  "return 3"
;;  :before "var __hoist = 3;"
;;  :hoistedName "__hoist"
;;  :selector (fn [node] (first (:body (:body node)))))

(assert-message 
 "pad.makeLine(1,2,3,4);" 
 "tell pad to makeLine"
 :before "var pad = {}; pad.makeLine = function(x1,y1,x2,y2) { return true; };"
 :selector (fn [node] (:expression node)))


;; --------------

;; (print "handling unknowns")
; (assert-message-code "a += 1" "[]")

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

