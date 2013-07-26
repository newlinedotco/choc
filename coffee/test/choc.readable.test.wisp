(ns choc.readable.test
  (:require [wisp.src.ast :as ast :refer [symbol keyword symbol? keyword?]]
            [wisp.src.sequence :refer [cons conj list list? seq vec empty? sequential?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse
                                       sort map filter reduce assoc]]
            [wisp.src.runtime :refer [str = dictionary]]
            [wisp.src.compiler :refer [self-evaluating? compile macroexpand macroexpand-1
                                       compile-program]]
            [wisp.src.reader :refer [read-from-string]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]
            [choc.readable.util :refer [to-set set-incl? partition]]
            ))

(defmacro ..
  ([x form] `(. ~x ~form))
  ([x form & more] `(.. (. ~x ~form) ~@more)))

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

(defn readable-node
  ([node] (readable-node node {}))
  ([node opts] 
     (cond 
      (= (:type node) "VariableDeclaration") 
      (do 
        (pp "Its a variable")
        ;(pp node)
        (map 
         (fn [dec]
           (let [name (.. dec -id -name)]
             `(:lineNumber ~(.. node -loc -start -line) 
               :message (~(str "create the variable <span class='choc-variable'>" name "</span> and set it to <span class='choc-value'>") ~(symbol name) "</span>")
               :timeline ~(symbol name))
             )) 
         (. node -declarations)))
      :else (do 
              (pp "its else")
              (pp node)
              ))))

(defmacro foo [thing]
  ``(+ ~thing "b"))

; (print (.to-string (foo "a")))
; (print (transpile (foo "a")))
; (print (transpile (foo f)))

;; (defmacro appendify-form-old 
;;   ; given ("a" "b" "c" "d")
;;   ; expands to (+ (+ (+ "a" "b") "c") "d")
;;   ([x form] ``(+ ~x ~form))
;;   ([x form & more] `(appendify-form (+ ~x ~form) ~@more)))

(defmacro appendify-form 
  ; given ("a" "b" "c" "d")
  ; expands to (+ (+ (+ "a" "b") "c") "d")
  [items] 
  `(print (count ~items))
  `(first 
    (reduce (fn [acc item] 
              (list (cons `+ (concat acc (list item))))) 
            (list (first ~items)) (rest ~items))))


(print "HERE--v")
(print (.to-string (macroexpand-1 `(appendify-form (list "hello" "foo" "c" "d")))))
(print (.to-string (macroexpand `(appendify-form (list "hello" "foo" "c" "d")))))
(print (.to-string (appendify-form (list "hello" "foo" "c" "d"))))
(print (transpile (appendify-form (list "hello" "foo" "c" "d" `f))))
(print (eval (transpile (appendify-form (list "hello" "foo" "c" "d")))))
(print "^--HERE")

(defn compile-message [message]
  (cond
   (symbol? message) message 
   (keyword? message) (str (ast.name message)) 
   (list? message) (appendify-form message)
   :else message))

(defn flatten-once 
  "poor man's flatten"
  [lists] (reduce (fn [acc item] (concat acc item)) lists))

(defn compile-readable-entry [node]
  ; (print "compile") 
  ; (print (.to-string (partition 2 node)))
  ; (print (count node))
  ; (pp (apply dictionary (vec node)))
  (let [compiled-pairs (map (fn [pair]
                (let [k (first pair) 
                      v (second pair)
                      str-key (str (ast.name k))
                      compiled-message (compile-message v)]
                  (list str-key compiled-message)))
              (partition 2 node))
        flat (flatten-once compiled-pairs)
        as-dict (apply dictionary (vec flat))]

    ;(print (.to-string compiled-pairs))
    ;(print (.to-string flat))
    ;(pp (apply dictionary (vec flat)))
    ;(print (transpile (apply dictionary (vec flat))))
    as-dict))

(defn compile-readable-entries [nodes]
  (map compile-readable-entry nodes)
  ;(map (fn []))
  ;; (print (.to-string (vec node)))
  ;; (pp (apply dictionary (vec node)))
  )

; (print (readable-node (pjs "var i = 0, j = 1;")))
;(print (.to-string (readable-node (pjs "var i = 0, j = 1;"))))
; (print (.to-string (readable-node (pjs "var i = 0, j = 1;"))))

(let [readable (readable-node (pjs "var i = 0, j = 1;"))]
  (print (.to-string readable))
  ;; here what you need to do is convert the output format to a format that compiles to a format which can be read by choc

  (compile-readable-entries readable)
  ;; (print (transpile readable))
  )

; (print (transpile `(+ "foo" "bar")))
; (print (transpile {"foo" `(+ "bar" bam)}))
; (print (transpile {"foo" `(+ "bar" ((fn [] "hello")))}))


(print "\n\n")
