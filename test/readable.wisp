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
            [choc.src.util :refer [to-set set-incl? partition transpile pp]]
            [choc.src.readable :refer [readable-node parse-js compile-readable-entries readable-js-str]]
            ))


(defn assert-message [js wanted & opts]
  (let [o (apply dictionary opts)
        parsed (first (parse-js js))
        readable (readable-node parsed)
        compiled (first (compile-readable-entries readable))
        ; _ (pp compiled)
        transpiled (transpile compiled)
        ; _ (puts transpiled)
        _ (eval js)
        message (eval (str "var __msg = " transpiled))]
    (assert (identical? (:message __msg) wanted) (str "message does not equal '" wanted "'"))))

(defn assert-message-code [js wanted & opts]
  (let [o (apply dictionary opts)
        code (readable-js-str (first (parse-js js)))]
    (assert (identical? code wanted) (str "code does not equal '" wanted "'"))))

(print "variable declarations")

(assert-message 
  "var i = 0" 
  "Create the variable <span class='choc-variable'>i</span> and set it to <span class='choc-value'>0</span>")

(print "handling unknowns")
(assert-message-code "a += 1" "[]")

