``` {.clojure .numberLines}
(defn learn
  [member* counter* nts]
  (let [member* (memoize member*)]
    (loop [g (init-grammar nts), blacklist #{}]
      (let [pg (prune-cfg g)]
        (if-let [c (counter* pg)]
          (if-let [t (parse-trees g c)]
            (let [bad-rules  (diagnose member* t)
                  bad-leaves (filter cnf-leaf? bad-rules)]
              (recur (reduce remove-rule g bad-rules)
                     (into blacklist bad-leaves)))

            (let [new-rules (candidate nts blacklist c)]
              (recur (reduce add-rule g new-rules)
                     blacklist)))
          pg)))))
```
