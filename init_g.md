``` {.clojure .numberLines}
(defn init-grammar
  [nts ts]
  (reduce add-rule (cfg)
          (candidates nts ts)))
```
