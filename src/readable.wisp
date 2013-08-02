(ns choc.readable
  (:require [wisp.ast :as ast :refer [symbol keyword symbol? keyword?]]
            [wisp.sequence :refer [cons conj list list? seq vec empty? sequential?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse
                                       sort map filter reduce assoc]]
            [wisp.runtime :refer [str = dictionary dictionary? fn? merge]]
            [wisp.compiler :refer [self-evaluating? compile macroexpand macroexpand-1
                                       compile-program]]
            [wisp.reader :refer [read-from-string]] 
            [wisp.string :as str :refer [join]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]
            [choc.readable.util :refer [to-set set-incl? partition pp transpile
                                        flatten-once parse-js when appendify-form appendify-to-str]]
            ))
; TODO implement condp in wisp and apply throughout

(defmacro ..
  ([x form] `(if ~x (. ~x ~form) nil)) ; TODO check for undefined - what about false?
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
  ([node opts]
     (let [o opts ; (if (dictionary? opts) opts (apply dictionary (vec opts)))
           _ (pp ["Generate readable expression" o node])
           type (:type node)
           op (:operator node)
           is-or-not (if (:negation o) " is not" " is")]
       (cond 
        (= type "AssignmentExpression") 
        (cond 
         (= "=" op) (list "set " (generate-readable-expression (:left node) {:want "name"}) 
                          " to " (generate-readable-value (:left node) (:right node)))
         (= "+=" op) (list "add " (generate-readable-expression (:right node)) 
                           " to " (generate-readable-expression (:left node) {:want "name"})
                           " and set " (generate-readable-expression (:left node) {:want "name"})
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
        ; callee / arguments
        (cond 
         (or (= (.. node -callee -type) "Identifier")
             (= (.. node -callee -type) "MemberExpression"))

         (let [callee-expression (generate-readable-expression (.. node -callee) {:want "name" :callArguments (.-arguments node)})
               callee-compiled (compile-message callee-expression)] 
           ;(list "call the function " callee-expression)
           `(((fn [] 
                (cond
                 ; ew - suggestions?
                 (.hasOwnProperty (eval ~callee-compiled) "__choc_annotation") 
                 (.__choc_annotation (eval ~callee-compiled) ~(.-arguments node))
                 true
                 (str "call the function " ~callee-compiled)))))
           )

         ;; unify these here and call the annotation?
         ;; and if there is no annotation, just call the callee-expresison -
         ;; except, you're going to need to be able to expand the
         ;; callee-expression within a function
         ;; if you tackle that, things might be a lot easier anyway

         true ""
         )

        (= type "CallExpressionXX")
        (let [callee-expression (generate-readable-expression (.. node -callee))
              target (or (.. node -callee -name) 
                         callee-expression)] 
          (cond
           (.. node -callee -object)    ; on a member object
           (list "tell "
                 (generate-readable-expression (.. node -callee -object) {:want "name"})
                 " to "
                 (generate-readable-expression (.. node -callee -property) {:want "name"}))

           (.. node -callee -name)      ; plain function call
           (list "call the function "
                 (generate-readable-expression (.. node -callee) {:want "name"})))

          `(((fn [] 
               (let [trg ~target]
                 (cond 
                  (.hasOwnProperty trg "__choc_annotation") 
                  (.__choc_annotation trg ~(.-arguments node))

                  ~(if (.. node -callee -name) true false) 
                  (str "call the function " ~(.. node -callee -name))

                  ~(if (.. node -callee -object -name) true false) 
                  (str "tell " ~(.. node -callee -object -name) 
                       " to " ~(.. node -callee -property -name)) 

                  ~(if target true false) 
                  (str "call " trg)     ; ? 
                  true ""
                  ))))))

        ; if you have a call expression
        ; it can have any number of member expressions
        ; so you need to pass down the symbol to the object you're talking about
        ; when do you decide if you use the annotation
        ; if you have a call expression when should you call the annotation?
        ; one of the things we haven't figured out yet, is if you're returning a function
        ; and you have a function inside there then we're screwed. e.g. we can't
        ; return functions within funcitons yet

        ;; if MemberExpression object.type is another member expression, then keep going

        (= type "MemberExpression") 
        (if (= (.. node -object -type) "MemberExpression")
          ; (generate-readable-expression (.-object node) {:want "name"})

          (list "" 
                (generate-readable-expression (.-object node) {:want "name"})
                "."
                (generate-readable-expression (.-property node) {:want "name"}))

          ;"xxx"
          ; object ; property
          (list "" 
                (generate-readable-expression (.-object node) {:want "name"})
                "."
                (generate-readable-expression (.-property node) {:want "name"}))

          )

        (= type "Literal") (:value node)
        (= type "Identifier") 

        (if (= (:want o) "name")
          (:name node)
          (symbol (:name node))

          ;; (let [target (:name node)] 
          ;;   `(((fn [] 
          ;;        (try 
          ;;          (cond
          ;;           (.hasOwnProperty ~(symbol target) "__choc_annotation") 
          ;;           (.__choc_annotation ~(symbol target) ~(:callArguments o))
          ;;           true
          ;;           ~target)
          ;;          (catch error 
          ;;              (print (str "Error in annotation for " ~target " : " error))
          ;;              "bobsyouruncle" ;~target
          ;;                 ))))))

                                        ; here instead of straight symbol, it should be a function 
                                        ; that way we can override ugly toStrings like Object
                                        ; and call our own annotations
          ; (symbol (:name node))
          ;; (let [target (:name node)]
          ;;     `(((fn []
          ;;       (cond 
          ;;        (.hasOwnProperty ~(symbol target) "__choc_annotation") 
          ;;        (.__choc_annotation ~(symbol target))
          ;;        (= (typeof ~(symbol target)) "object") "an object"
          ;;        true ~(symbol target))))))

          ;; (let [target (:name node)]
          ;;   `(((fn [] 
          ;;        (cond 
          ;;         (.hasOwnProperty ~(symbol target) "__choc_annotation") 
          ;;         (.__choc_annotation ~(symbol target))
          ;;         (= (typeof ~(symbol target)) "object") "an object"
          ;;         true ~(symbol target)
          ;;         )
          ;;        ))))
          )

        (= type "VariableDeclarator") 
        (cond 
         (= (:want o) "name") (generate-readable-expression (.. node -id) {:want "name"})
         true (generate-readable-expression (.. node -id)) )

        true `("")

        ))))

; return a fn of a compiled entry everytime

(defn make-opts [opts]
  (if (dictionary? opts) 
    opts 
    (apply dictionary (vec opts)))) ; apply vec opts?

(defn readable-node
  ([node] (readable-node node {}))
  ([node opts] 
     (pp node)
     (let [o (make-opts opts)
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
                                                   "</span> and set it to <span class='choc-value'>") (generate-readable-expression dec)
                                                   "</span>")
                               :timeline (symbol name))))) 
                         (. node -declarations)))] 
          `((fn [] ~messages)))

        (= "WhileStatement" t)
        (let [conditional (if (:hoistedName o) 
                            (symbol (:hoistedName o))
                            true)
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
                                :message (list "Because " (generate-readable-expression (:test node) {:negation true}) )
                                :timeline "f"
                                ))
                              (compile-entry 
                               (list
                                :lineNumber (.. node -loc -end -line) 
                                :message (list "... stop looping")
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


        (= "ReturnStatement" t)
        (let [messages [(compile-entry 
                          (list 
                           :lineNumber (.. node -loc -start -line)
                           :message (list "return " (symbol (:hoistedName o)))))]]
          `((fn [] ~messages)))


        ; handle receiving an expression directly - TODO possible code smell
        (= "CallExpression" t)
        (let [messages [(compile-entry 
                          (list 
                           :lineNumber (.. node -loc -start -line)
                           :message (generate-readable-expression node)))]]
          `((fn [] ~messages)))




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
        ; _ (print (.to-string compiled-pairs))
        flat (flatten-once compiled-pairs)
        ; _ (print (.to-string flat))
        as-dict (apply dictionary (vec flat))
        ; _ (pp as-dict)
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
  ; (print opts)
  (let [readable (readable-node node opts)
        ; compiled (compile-readable-entries readable)
        ; _ (print "compiled")
        ; _ (print compiled)
        transpiled (transpile readable)
        ; _ (print "transpiled")
        ; _ (print transpiled)
        result (if readable
                 transpiled
                 "''")
        ;_ (print "result")
        ;_ (print result)
        ]
   result
   ; "''"
   ))
