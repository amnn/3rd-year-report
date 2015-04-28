```{.clojure .numberLines}
(defn learn
  [member* counter* nts ts]
  (let [[memo member] (soft-memoize member*)]
    (loop         [g  (init-grammar nts ts)]
      (let        [pg (prune-cfg g)]
        (if-let   [c  (counter* pg)]
          (if-let [t  (parse-trees g c)]
            (recur (reduce remove-rule g (diagnose member t)))
            (do (requery memo)
                (recur (reduce add-rule g (candidates nts c)))))
          pg)))))
```
