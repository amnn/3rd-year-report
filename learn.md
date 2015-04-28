``` {.clojure .numberLines}
(defn learn
  [member* counter* nts ts]
  (loop [g       (init-grammar nts ts)
         member? (memoize member*)]
    (let        [pg (prune-cfg g)]
      (if-let   [c  (counter* pg)]
        (if-let [t  (parse-trees g c)]
          (recur (reduce remove-rule g (diagnose member? t))
                 member?)
          (recur (reduce add-rule    g (candidates nts c))
                 (memoize member*)))
        pg))))
```
