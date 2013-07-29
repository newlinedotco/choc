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
                                        flatten-once parse-js when]]
            ))
; TODO implement condp in wisp and apply throughout

(defmacro ..
  ([x form] `(. ~x ~form))
  ([x form & more] `(.. (. ~x ~form) ~@more)))

(defn generate-readable-value 
  ([node1 node2] (generate-readable-value node1 node2 {}))
  ([node1 node2 opts]
     (if (.hasOwnProperty node1 :name)
       (symbol (:name node1))
       (cond 
        (= "FunctionExpression" (:type node2)) "this function"
        :else "TODO" ))))

(defn generate-readable-expression 
  ([node] (generate-readable-expression node {}))
  ([node & opts]
     (pp node)
     (let [o (apply dictionary opts)
           type (:type node)
           op (:operator node)]
       (cond 
        (= type "AssignmentExpression") 
        (cond 
         (= "=" op) (list "set " (generate-readable-expression (:left node) :want "name") 
                          " to " (generate-readable-value (:left node) (:right node)))
         (= "+=" op) (list "add " (generate-readable-expression (:right node)) 
                           " to " (generate-readable-expression (:left node) :want "name")
                           " and set " (generate-readable-expression (:left node) :want "name")
                           " to " (generate-readable-value (:left node) (:right node))
                           )
         )
        (= type "BinaryExpression")
        (do
          ;(pp node)
          (cond
         ;(= "+" op) (symbol (:name (:left node)))
           ))

        (= type "CallExpression")
        (do
          (print "CALLEXPRESS")
          `(((fn [] 
               (if true (list "tell foo to bar"))))))

        (= type "MemberExpression") 
        (do
          (print "MEMBER")
          (pp node)
          (list "TODO"))

        (= type "Literal") (:value node)
        (= type "Identifier") (if (= (:want o) "name")
                                (:name node)
                                (symbol (:name node)))

        ))))

(defn readable-node
  ([node] (readable-node node {}))
  ([node opts] 
     ; (pp node)
     (let [t (:type node)] 
       (cond
        (= "VariableDeclaration" t) 
        (map 
         (fn [dec]
           (let [name (.. dec -id -name)]
             (list 
              :lineNumber (.. node -loc -start -line) 
              :message (list (str "Create the variable <span class='choc-variable'>" name "</span> and set it to <span class='choc-value'>") (symbol name) "</span>")
              :timeline (symbol name)))) 
         (. node -declarations))

        ;; (= "ExpressionStatement" t)
        ;; (let [expression (or (generate-readable-expression (:expression node)) (list ""))]
        ;;   (list 
        ;;    (list 
        ;;     :lineNumber (.. node -loc -start -line)
        ;;     :message expression)))

        ;; (= "CallExpression" t)
        ;; (let [expression (or (generate-readable-expression node) (list ""))]
        ;;   (list 
        ;;    (list 
        ;;     :lineNumber (.. node -loc -start -line)
        ;;     :message expression)))


        ;; :else
        ;; (do 
        ;;         (pp "its else")
        ;;         (pp node)
        ;;         `()
        ;;         )
        ))))


; given ("a" "b" "c" "d")
; expands to (+ (+ (+ "a" "b") "c") "d")
(defn appendify-form 
  [items] 
  (first 
   (reduce (fn [acc item] 
             (list (cons `+ (concat acc (list item))))) 
           (list (first items)) (rest items))))

;; (defn appendify-list [source]
;;   (loop [result []
;;          list source]
;;     (if (empty? list)
;;       result
;;       (recur
;;         (do (.push result (first list)) result)
;;         (rest list)))))


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
        _ (print "compiled")
        _ (print compiled)
        transpiled (transpile compiled)
        _ (print "transpiled")
        _ (print transpiled)
        result (if compiled
                 transpiled
                 "''")
        _ (print "result")
        _ (print result)]
   result))
