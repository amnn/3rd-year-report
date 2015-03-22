```{.clojure .numberLines}
(defn- null-trans-rule? [[s & rs]]
  (every? (every-pred non-terminal? #(not= s %)) rs))

(defn- null-trans-graph [g]
  (filter null-trans-rule? (rule-seq g)))

(defn nullable [g] (->> g null-trans-graph horn-sat))
```
