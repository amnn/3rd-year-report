``` {.clojure .numberLines}
(defrecord ^:private MultiBranch [nt yield children])
(defrecord ^:private MultiLeaf   [nt yield children])

(defn parse-trees
  ([g ts] (parse-trees g :S ts))

  ([g root ts]
   (let [{branches true leaves false}
         (group-by cnf-branch?
                   (cfg/rule-seq g))]
     (parse-tree*
      :branches branches, :leaves leaves
      :root root, :ts ts

      :->branch
      (fn [nt rule yield lt rt]
        (->MultiBranch nt yield #{[rule lt rt]}))

      :->leaf
      (fn [nt rule yield]
        (->MultiLeaf nt yield #{[rule]}))

      :merge-fn
      (fn [b1 b2]
        (update-in b1 [:children] union
                   (:children b2)))

      :rule identity))))
```
