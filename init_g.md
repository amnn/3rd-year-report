``` {.clojure .numberLines}
(defn- init-grammar
  [nts]
  (reduce add-rule (cfg)
          (for [a nts b nts c nts]
            [a b c])))
```
