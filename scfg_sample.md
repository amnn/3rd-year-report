```{.clojure .numberLines}
(defn- scfg-sample
  [sg n] (vec (repeatedly n #(sample sg))))

(defn sample
  ([sg] (sample sg [:S]))

  ([sg deriv]
   (if (every? terminal? deriv)
     deriv
     (letfn [(pick-rule [nt]
               (let [rules (get sg nt {})]
                 (first
                   (simple/sample (keys rules)
                                  :weigh rules))))]
       (->> deriv
            (map #(cond-> %
                    (non-terminal? %)
                    pick-rule))
            flatten vec
            (recur sg))))))
```
