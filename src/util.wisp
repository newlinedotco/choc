(ns choc.readable.util
  (:require [wisp.ast :refer [symbol keyword]]
            [wisp.sequence :refer [cons conj list list? seq vec empty?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse
                                       sort map filter reduce assoc]]
            [wisp.runtime :refer [str = dictionary]]
            [wisp.compiler :refer [self-evaluating? compile macroexpand
                                       compile-program]]
            [wisp.reader :refer [read-from-string]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]))

(defn to-set [col] 
  (let [pairs (reduce (fn [acc item] (concat acc [item true])) [] col)]
    (apply dictionary (vec pairs))))

(defn set-incl? [set key]
  (.hasOwnProperty set key))

(defn partition
  "Returns a lazy sequence of lists of n items each, at offsets step
  apart. If step is not supplied, defaults to n, i.e. the partitions
  do not overlap. If a pad collection is supplied, use its elements as
  necessary to complete last partition upto n items. In case there are
  not enough padding elements, return a partition with less than n items."
  ([n coll]
     (partition n n coll))
  ([n step coll]
     (loop [result []
            items coll]
       (let [group (take n items)]
         (if (= n (count group))
           (recur (conj result group)
                  (drop step items))
           result))))
  ([n step pad coll]
   (partition n step (concat coll pad))))

