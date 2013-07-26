(ns choc.readable
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
            [choc.readable.util :refer [to-set set-incl? partition pp transpile
                                        flatten-once parse-js appendify-form]]
            ))

(defmacro ..
  ([x form] `(. ~x ~form))
  ([x form & more] `(.. (. ~x ~form) ~@more)))

(defn readable-node
  ([node] (readable-node node {}))
  ([node opts] 
     (cond 
      (= (:type node) "VariableDeclaration") 
      (map 
       (fn [dec]
         (let [name (.. dec -id -name)]
           (list 
            :lineNumber (.. node -loc -start -line) 
            :message (list (str "Create the variable <span class='choc-variable'>" name "</span> and set it to <span class='choc-value'>") (symbol name) "</span>")
            :timeline (symbol name)))) 
       (. node -declarations))

      (= (:type node) "ExpressionStatement") 
      (list 
       (list 
        :lineNumber (.. node -loc -start -line)
        :message (list "axb")))

      :else (do 
              (pp "its else")
              (pp node)
              `()
              ))))

(defn compile-message [message]
  (cond
   (symbol? message) message 
   (keyword? message) (str (ast.name message)) 
   (list? message) (appendify-form message)
   :else message))

(defn compile-readable-entry [node]
  (let [compiled-pairs (map (fn [pair]
                (let [k (first pair) 
                      v (second pair)
                      str-key (str (ast.name k))
                      compiled-message (compile-message v)]
                  (list str-key compiled-message)))
              (partition 2 node))
        flat (flatten-once compiled-pairs)
        as-dict (apply dictionary (vec flat))]
    as-dict))

(defn compile-readable-entries [nodes]
  (if (empty? nodes)
    []
    (map compile-readable-entry nodes)))

(defn readable-js-str 
  "This API is a little weird. Given an esprima parsed code tree, returns a string of js code. Maybe this should just return an esprima tree."
  [node]
  (let [readable (readable-node node)
        compiled (compile-readable-entries readable)
        transpiled (transpile compiled)]
    transpiled))
