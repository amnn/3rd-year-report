``` {.clojure .numberLines}
(defn contributing-nts
  "Returns the non-terminals that can yield strings."
  [g] (->> g cfg/rule-seq horn-sat))
```
