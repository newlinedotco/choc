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
            [escodegen :as escodegen]
            [underscore :refer [has]]
            [util :refer [puts inspect]]
            [choc.readable.util :refer [to-set set-incl? partition pp transpile
                                        flatten-once parse-js when appendify-form appendify-to-str]]
            ))


(defmacro ..
  ([x form] `(if ~x (. ~x ~form) nil)) ; TODO check for undefined - what about false?
  ([x form & more] `(.. (. ~x ~form) ~@more)))

(defn generate-readable-value 
  ([node1 node2] (generate-readable-value node1 node2 {}))
  ([node1 node2 opts]
     (print node1)
     (print node2)
     (if (.hasOwnProperty node1 :name)
       (symbol (:name node1))
       (cond 
        (= "FunctionExpression" (:type node2)) "this function"
        true (generate-readable-expression node2)
        :else "" ))))

(defn generate-readable-expression 
  ([node] (generate-readable-expression node {}))
  ([node opts]
     (let [o opts
           type (:type node)
           op (:operator node)
           is-or-not (if (:negation o) " is not" " is")]
       (cond ; TODO implement condp in wisp
        (= type "AssignmentExpression") 
        (cond 
         (= "=" op) (list "set " (generate-readable-expression (:left node) {:want "name"}) 
                          " to " (generate-readable-value (:left node) (:right node)))
         (= "+=" op) (list "add " (generate-readable-expression (:right node)) 
                           " to " (generate-readable-expression (:left node) {:want "name"})
                           " and set " (generate-readable-expression (:left node) {:want "name"})
                           " to " (generate-readable-value (:left node) (:right node)))
         (= "-=" op) (list "subtract " (generate-readable-expression (:right node)) 
                           " from " (generate-readable-expression (:left node) {:want "name"})
                           " and set " (generate-readable-expression (:left node) {:want "name"})
                           " to " (generate-readable-value (:left node) (:right node)))
         (= "*=" op) (list "multiply " (generate-readable-expression (:left node) {:want "name"})
                           " by " (generate-readable-expression (:right node)) 
                           " and set " (generate-readable-expression (:left node) {:want "name"})
                           " to " (generate-readable-value (:left node) (:right node)))
         (= "/=" op) (list "divide " (generate-readable-expression (:left node) {:want "name"})
                           " by " (generate-readable-expression (:right node)) 
                           " and set " (generate-readable-expression (:left node) {:want "name"})
                           " to " (generate-readable-value (:left node) (:right node)))
         (= "%=" op) (list "divide " (generate-readable-expression (:left node) {:want "name"})
                           " by " (generate-readable-expression (:right node)) 
                           " and set " (generate-readable-expression (:left node) {:want "name"})
                           " to the remainder: " (generate-readable-value (:left node) (:right node)))
         
         )
        (= type "BinaryExpression")
        (let [truthy (fn [node verbiage]
                       (list (generate-readable-expression (:left node)) 
                             is-or-not
                             verbiage
                             (generate-readable-expression (:right node))))
              opy (fn [node verbiage]
                    (list (generate-readable-expression (:left node)) 
                          verbiage
                          (generate-readable-expression (:right node))))]
          (cond
           (= "+" op) (opy node " plus ")
           (= "-" op) (opy node " minus ")
           (= "*" op) (opy node " times ")
           (= "/" op) (opy node " divided by ")
           (= "%" op) (opy node " modulo ")
           (= "|" op) (opy node " bitwise-or ")
           (= "^" op) (opy node " bitwise-and ")
 
           (= "<="  op) (truthy node " less than or equal to ") 
           (= "=="  op) (truthy node " equal to ") 
           (= "===" op) (truthy node " equal to ") 
           (= "!="  op) (truthy node " not equal to ")
           (= "<"   op) (truthy node " less than ") 
           (= "<="  op) (truthy node " less than or equal to ") 
           (= ">"   op) (truthy node " greater than ") 
           (= ">="  op) (truthy node " greater than or equal to ") 
           true (str "")
           ))

        ;; operators = 
        ;;   "<<": "#{node.left.name}"
        ;;   ">>": "#{node.left.name}"
        ;;   ">>>": "#{node.left.name}"
        ;;   "in": "''"
        ;;   "instanceof": "''"
        ;;   "..": "''"

        (= type "ObjectExpression")
        (list "an object")

        (= type "CallExpression")
                                        ; callee / arguments
        (cond 
         (or (= (.. node -callee -type) "Identifier")
             (= (.. node -callee -type) "MemberExpression"))

         (let [;; given foo.bar.baz()...
              
               ;; callee-compiled is a reference to the object and property we're calling
               ;; e.g. foo.bar.baz
               callee-expression (generate-readable-expression (.-callee node) {:want "name"})
               callee-compiled (compile-message callee-expression)

               ;; callee-object-compiled is just the object without the property we're calling
               ;; e.g. foo.bar
               callee-object (generate-readable-expression (.. node -callee -object) {:want "name"})
               callee-object-compiled (compile-message callee-object)

               ;; propertyN is just the property being called
               ;; e.g. baz
               propertyN (.. node -callee -property -name)

               ;; Here we are eval'ing the arguments being passed into the
               ;; function call so that we can have a clean api for implementing
               ;; annotations.
               ;;
               ;; There are so many reasons why this is bad. We should be
               ;; hoisting the function arguments instead of evaling them
               ;; here. (Or write our own JS interpreter so then we don't need
               ;; to source rewrites at all. See metajs)
               ;;
               ;; Furthermore, this straight up wont work if the arguments are state changing.
               ;; TODO generate these arguments in a proper way
               argumentSources (map (fn [arg] (.generate escodegen arg {format: { compact: false }})) 
                                    (.-arguments node))] 
           `(((fn [] 
                (let [callee (eval ~callee-compiled)
                      callee-object (eval ~callee-object-compiled)
                      arguments (map (fn [arg] (eval arg)) ~argumentSources)] 
                  (readable/annotation-for callee callee-object ~callee-compiled ~propertyN arguments))
                ))))
         true "")

        (= type "MemberExpression") 
        (list "" 
              (generate-readable-expression (.-object node)   {:want "name"}) "."
              (generate-readable-expression (.-property node) {:want "name"}))

        (= type "Literal") 
        (:value node)

        (= type "Identifier") 
        (if (= (:want o) "name")
          (:name node)
          (symbol (:name node)))

        (= type "VariableDeclarator") 
        (cond 
         (= (:want o) "name") (generate-readable-expression (.. node -id) {:want "name"})
         true (generate-readable-expression (.. node -id)) )

        true `("")
        ))))

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
                           :message (generate-readable-expression (:expression node) opts)))]]
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
                           :message (generate-readable-expression node opts)))]]
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
        flat (flatten-once compiled-pairs)
        as-dict (apply dictionary (vec flat))]
    as-dict))

(defn readable-js-str 
  "This API is a little weird. Given an esprima parsed code tree, returns a string of js code. Maybe this should just return an esprima tree."
  [node opts]
  (let [readable (readable-node node opts)
        transpiled (transpile readable)
        result (if readable
                 transpiled
                 "''")]
   result))

(defn- find-annotation-for [obj propertyName args]
  (let [proto (.-prototype (.-constructor obj))] 
    (cond
     ;; Check the instance itself for a particular annotation
     (.hasOwnProperty obj "__choc_annotation") 
     (.__choc_annotation obj args)

     ;; Check the instance itself for a set of annotations
     (and (.hasOwnProperty obj "__choc_annotations")
          (.hasOwnProperty (get obj "__choc_annotations") propertyName)) 
     ((get (get obj "__choc_annotations") propertyName) args)
     
     ;; Check the instance constructor prototype for a dictionary of named __choc_annotations
     (and (.hasOwnProperty proto "__choc_annotations")
          (.hasOwnProperty (get proto "__choc_annotations") propertyName)) 
     ((get (get proto "__choc_annotations") propertyName) args)
     true false)))

(defn annotation-for 
  "searches the annotation chain given the arguments. calls the annotation and
returns the message to be displayed"
  [callee callee-object callee-compiled propertyName args]
  (let [callee-annotation (find-annotation-for callee propertyName args)] 
    (if callee-annotation
      callee-annotation
      (let [callee-object-annotation (if callee-object 
                                       (find-annotation-for callee-object propertyName args) 
                                       false)]
        (if callee-object-annotation
          callee-object-annotation
          (str "call the function " callee-compiled))))))


