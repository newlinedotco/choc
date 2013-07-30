(ns choc.readable
  (:require [wisp.ast :as ast :refer [symbol keyword symbol? keyword?]]
            [wisp.sequence :refer [cons conj list list? seq vec empty? sequential?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse
                                       sort map filter reduce assoc]]
            [wisp.runtime :refer [str = dictionary dictionary? fn?]]
            [wisp.compiler :refer [self-evaluating? compile macroexpand macroexpand-1
                                       compile-program]]
            [wisp.reader :refer [read-from-string]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]
            [choc.readable.util :refer [to-set set-incl? partition pp transpile
                                        flatten-once parse-js when appendify-form]]
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
     ; (pp node)
     (let [o (if (dictionary? opts) opts (apply dictionary (vec opts)))
           type (:type node)
           op (:operator node)
           is-or-not (if (:negation o) " is not" " is")]
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
          (= "<=" op) (list (generate-readable-expression (:left node)) 
                            is-or-not
                            " less than or equal to " 
                            (generate-readable-expression (:right node)))
          (= "+" op) (list (generate-readable-expression (:left node)) 
                            " plus " 
                            (generate-readable-expression (:right node)))))

        (= type "CallExpression")
        (cond
         (.. node -callee -object) ; on a member object
         (list "tell "
               (generate-readable-expression (.. node -callee -object) :want "name")
               " to "
               (generate-readable-expression (.. node -callee -property) :want "name"))

         (.. node -callee -name) ; plain function call
         (list "call the function "
               (generate-readable-expression (.. node -callee) :want "name")))

        ;; `(((fn [] 
        ;;      (if true (list "tell foo to bar")))))
        

        (= type "MemberExpression") 
        (do
          (print "MEMBER")
          (pp node)
          (list "TODO"))

        (= type "Literal") (:value node)
        (= type "Identifier") (if (= (:want o) "name")
                                (:name node)
                                (symbol (:name node)))

        true `("")

        ))))

; return a fn of a compiled entry everytime

(defn readable-node
  ([node] (readable-node node {}))
  ([node & opts] 
     (pp node)
     (let [o (apply dictionary (apply vec opts))
           t (:type node)] 
       (cond
        (= "VariableDeclaration" t) 
        (let [messages (vec 
                        (map 
                         (fn [dec]
                           (let [name (.. dec -id -name)]
                             (compile-entry 
                              (list 
                               :lineNumber (.. node -loc -start -line) 
                               :message (list (str "Create the variable <span class='choc-variable'>" name 
                                                   "</span> and set it to <span class='choc-value'>") (symbol name) 
                                                   "</span>")
                               :timeline (symbol name))))) 
                         (. node -declarations)))] 
          `((fn []
              ~messages)))

        (= "WhileStatement" t)
        (let [conditional (or (:hoistedName o) true)
              true-messages [(compile-entry 
                              (list
                               :lineNumber (.. node -loc -start -line) 
                               :message (list "Because " (generate-readable-expression (:test node)) )
                               :timeline "t"
                               ))
                             (compile-entry 
                              (list
                               :lineNumber (.. node -loc -end -line) 
                               :message (list "... and try again")
                               :timeline ""))
                             ]
              false-messages [(compile-entry 
                               (list
                                :lineNumber (.. node -loc -start -line) 
                                :message (list "Because " (generate-readable-expression (:test node) :negation true) )
                                :timeline "f"
                                ))
                              (compile-entry 
                               (list
                                :lineNumber (.. node -loc -end -line) 
                                :message (list "... and stop looping")
                                :timeline ""))
                              ]
              ]
          `((fn [condition]
              (if condition
                ~true-messages
                ~false-messages)) ~conditional))
        
        (= "ExpressionStatement" t)
        (let [messages [(compile-entry 
                          (list 
                           :lineNumber (.. node -loc -start -line)
                           :message (generate-readable-expression (:expression node))))]]
          `((fn [] ~messages)))

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


(defn compile-message [message]
  (cond
   (symbol? message) message 
   (keyword? message) (str (ast.name message)) 
   (list? message) (appendify-form message)
   :else message))

(defn compile-entry 
  "converts a list of kv pairs into a compiled javascript object"
  [node]
  (let [compiled-pairs (map (fn [pair]
                (let [k (first pair) 
                      v (second pair)
                      str-key (str (ast.name k))
                      compiled-message (compile-message v)]
                  (list str-key compiled-message)))
              (partition 2 node))
        _ (print (.to-string compiled-pairs))
        flat (flatten-once compiled-pairs)
        _ (print (.to-string flat))
        as-dict (apply dictionary (vec flat))
        _ (pp as-dict)
        ]
    as-dict))

(defn compile-readable-entries [nodes]
  (if (fn? nodes)
    nodes
    (if (empty? nodes)
      []
      (map compile-entry nodes)))
  )

(defn readable-js-str 
  "This API is a little weird. Given an esprima parsed code tree, returns a string of js code. Maybe this should just return an esprima tree."
  [node opts]
  (print opts)
  (let [readable (readable-node node opts)
        ; compiled (compile-readable-entries readable)
        ; _ (print "compiled")
        ; _ (print compiled)
        transpiled (transpile readable)
        _ (print "transpiled")
        _ (print transpiled)
        result (if readable
                 transpiled
                 "''")
        _ (print "result")
        _ (print result)]
   result))
