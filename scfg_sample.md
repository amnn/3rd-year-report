```{.clojure .numberLines}
(defn scfg-sample
  ([sg] (scfg-sample sg :S))

  ([sg nt]
   (letfn [(pick-rule [nt]
             (let [rules (get sg nt {})]
               (first (simple/sample (keys rules)
                                     :weigh rules))))

           (recur-left [[nt & rhs]]
             (concat (pick-rule nt) rhs))]
     (loop [lhs (transient [])
            rhs (list nt)]
       (if (seq rhs)
         (let [[l r] (split-with terminal? (recur-left rhs))]
           (recur (concat! lhs l) r))
         (persistent! lhs))))))
```
