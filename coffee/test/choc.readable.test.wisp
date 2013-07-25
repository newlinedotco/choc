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

(defn parse-js [code]
  (.parse esprima code {:range true :loc true}))

(defn to-set [col] 
  (let [pairs (reduce (fn [acc item] (concat acc [item true])) [] col)]
    (apply dictionary (vec pairs))))

(defmacro any* [pred expr & matches]
  (let [tests [(fn [x] true) 1 2]]
    tests))


(defmacro ->
  [& operations]
  (reduce
   (fn [form operation]
     (cons (first operation)
           (cons form (rest operation))))
   (first operations)
   (rest operations)))

(defmacro ->+
  [& operations]
  (reduce
   (fn [form operation]
     (concat operation (list form)))
   (first operations)
   (rest operations)))

; (print (cons 1 [2]))

(defn inc [x] (+ x 1))
(defn even? [x] (== x 2))

;; (pp 
;;  (->
;;   [1 2 3]
;;   (map inc)
;;   (filter even?)))

(pp "macro")

(pp 
 (->+
  [1 2 3]
  (map inc)
  (filter even?)))

; go to ->
; (filter even? (map inc [1 2 3]))

;; (map
;;  (fn [x] (fn [y] (+ x y)))
;;  [1 2 3])


; (pp {:foo 1})
; (pp (parse-js "var foo = 1;"))

(print "wisp")
;(map (fn [x] (pp x)) [1 2 3])
(pp (any* = "foo" "bing" "bar" "baz"))

(let [members (to-set ["foo" "bar" "baz"])]
 (pp (has members "foo"))
 (pp (has members "bring")))

(print "done")
(print "")
