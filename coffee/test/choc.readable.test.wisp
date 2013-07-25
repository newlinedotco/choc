(ns choc.readable.test
  (:require [wisp.src.ast :refer [symbol]]
            [wisp.src.sequence :refer [cons conj list list? seq vec empty?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse
                                       sort map filter reduce assoc]]
            [wisp.src.runtime :refer [str = dictionary]]
            [wisp.src.compiler :refer [self-evaluating? compile macroexpand
                                       compile-program]]
            [wisp.src.reader :refer [read-from-string]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]))

(defn transpile [& forms] (compile-program forms))
(defn pp [form] (puts (inspect form null 100 true)))

(defn parse-js 
  "parses a string code of javascript into a parse tree. Returns an array of the
statements in the body"
  ([code] (parse-js code {:range true :loc true}))
  ([code opts]
     (let [program (.parse esprima code opts)]
       (:body program))))

(defn pjs [code] (first (parse-js code)))

(defn to-set [col] 
  (let [pairs (reduce (fn [acc item] (concat acc [item true])) [] col)]
    (apply dictionary (vec pairs))))

(defn set-incl? [set key]
  (.hasOwnProperty set key))

(let [items (to-set ["foo" "bar"])]
  (pp (set-incl? items "foo")))

(defmacro ..
  ([x form] `(. ~x ~form))
  ([x form & more] `(.. (. ~x ~form) ~@more)))

(defn readable-node
  ([node] (readable-node node {}))
  ([node opts] 
     (cond 
       (= (:type node) "VariableDeclaration") 
       (do 
         (pp "Its a variable")
         (pp node)
         (print (.to-string `(.. node -loc -start -line)))
         (print (.to-string `(:lineNumber ~(.. node -loc -start -line) :message (str "some message " foo))))
         )
       :else (do 
               (pp "its else")
               (pp node)
               ))))

(readable-node (pjs "var i = 0;"))

;; (defmacro any* [pred expr & matches]
;;   (let [tests [(fn [x] true) 1 2]]
;;     tests))

;; (cond
;;  (= x statementsx)
;;  )

;; (defmacro ->
;;   [& operations]
;;   (reduce
;;    (fn [form operation]
;;      (cons (first operation)
;;            (cons form (rest operation))))
;;    (first operations)
;;    (rest operations)))

;; (defmacro ->+
;;   [& operations]
;;   (reduce
;;    (fn [form operation]
;;      (concat operation (list form)))
;;    (first operations)
;;    (rest operations)))

; (print (cons 1 [2]))

;; (defn inc [x] (+ x 1))
;; (defn even? [x] (== x 2))

;; (pp 
;;  (->
;;   [1 2 3]
;;   (map inc)
;;   (filter even?)))

;; (pp "macro")

;; (pp 
;;  (->+
;;   [1 2 3]
;;   (map inc)
;;   (filter even?)))

; go to ->
; (filter even? (map inc [1 2 3]))

;; (map
;;  (fn [x] (fn [y] (+ x y)))
;;  [1 2 3])


; (pp {:foo 1})
; (pp (parse-js "var foo = 1;"))

;(map (fn [x] (pp x)) [1 2 3])
;; (pp (any* = "foo" "bing" "bar" "baz"))

;; (let [members (to-set ["foo" "bar" "baz"])]
;;  (pp (has members "foo"))
;;  (pp (has members "bring")))

(print "done")
(print "")
